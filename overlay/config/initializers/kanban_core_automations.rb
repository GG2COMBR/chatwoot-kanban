# frozen_string_literal: true

# Inicializador de integração do Kanban com Automações e Macros nativas do Chatwoot.
#
# Segue a política arquitetural definida em docs/ARCHITECTURE.md:
# Evita patches nos controllers, models e services de automação/macro do core
# injetando os pontos de extensão dinamicamente em tempo de boot (to_prepare).

Rails.application.config.to_prepare do
  KANBAN_AUTOMATION_ACTIONS = %w[add_to_kanban_board move_kanban_card assign_kanban_card].freeze

  # ---------------------------------------------------------------------------
  # 1. ActionService: inclui concern com executores das 3 ações de funil
  # ---------------------------------------------------------------------------
  if defined?(ActionService) && defined?(KanbanActionService)
    ActionService.include(KanbanActionService) unless ActionService.ancestors.include?(KanbanActionService)
  end

  # ---------------------------------------------------------------------------
  # 2. AutomationRule: adiciona ações à whitelist permitida
  # ---------------------------------------------------------------------------
  if defined?(AutomationRule)
    module ::KanbanAutomationRuleExtension
      def actions_attributes
        super + KANBAN_AUTOMATION_ACTIONS
      end
    end

    AutomationRule.prepend(::KanbanAutomationRuleExtension) unless AutomationRule.ancestors.include?(::KanbanAutomationRuleExtension)
  end

  # ---------------------------------------------------------------------------
  # 3. Macro: permite ações de funil na validação json_actions_format
  # ---------------------------------------------------------------------------
  if defined?(Macro)
    module ::KanbanMacroExtension
      def json_actions_format
        return if actions.blank?

        attributes = actions.map { |obj, _| obj['action_name'] }
        unsupported = attributes - (Macro::ACTIONS_ATTRS + KANBAN_AUTOMATION_ACTIONS)

        errors.add(:actions, "Macro execution actions #{unsupported.join(',')} not supported.") if unsupported.any?
      end
    end

    Macro.prepend(::KanbanMacroExtension) unless Macro.ancestors.include?(::KanbanMacroExtension)
  end

  # ---------------------------------------------------------------------------
  # 4. Labels::UpdateService: sincroniza renomeação de labels em KanbanCard
  # ---------------------------------------------------------------------------
  if defined?(Labels::UpdateService)
    module ::KanbanLabelsUpdateServiceExtension
      def perform
        super
        update_tagged_kanban_cards
      end

      private

      def update_tagged_kanban_cards
        return unless defined?(KanbanCard)

        KanbanCard.where(account_id: account_id).tagged_with(old_label_title).find_in_batches do |card_batch|
          card_batch.each do |card|
            card.label_list.remove(old_label_title)
            card.label_list.add(new_label_title)
            card.save!
          end
        end
      end
    end

    Labels::UpdateService.prepend(::KanbanLabelsUpdateServiceExtension) unless Labels::UpdateService.ancestors.include?(::KanbanLabelsUpdateServiceExtension)
  end

  # ---------------------------------------------------------------------------
  # 5. AutomationRulesController: estende strong params com action_params de funil
  # ---------------------------------------------------------------------------
  if defined?(Api::V1::Accounts::AutomationRulesController)
    module ::KanbanAutomationRulesControllerExtension
      private

      def automation_rules_permit
        permitted_attributes = [:name, :description, :event_name, :active]
        if respond_to?(:delayed_automations_enabled?, true) && delayed_automations_enabled?
          permitted_attributes += [:execution_delay, :execution_delay_trigger]
        end

        params.permit(
          *permitted_attributes,
          conditions: [:attribute_key, :filter_operator, :query_operator, :custom_attribute_type, { values: [] }],
          actions: [
            :action_name,
            { action_params: [:kanban_board_id, :kanban_stage_id, :message, { agent_ids: [], team_ids: [] }] },
            { action_params: [] }
          ]
        )
      end
    end

    Api::V1::Accounts::AutomationRulesController.prepend(::KanbanAutomationRulesControllerExtension) unless Api::V1::Accounts::AutomationRulesController.ancestors.include?(::KanbanAutomationRulesControllerExtension)
  end

  # ---------------------------------------------------------------------------
  # 6. MacrosController: estende strong params com action_params de funil
  # ---------------------------------------------------------------------------
  if defined?(Api::V1::Accounts::MacrosController)
    module ::KanbanMacrosControllerExtension
      private

      def permitted_params
        params.permit(
          :name, :visibility,
          actions: [
            :action_name,
            { action_params: [:kanban_board_id, :kanban_stage_id, :message, { agent_ids: [], team_ids: [] }] },
            { action_params: [] }
          ]
        )
      end
    end

    Api::V1::Accounts::MacrosController.prepend(::KanbanMacrosControllerExtension) unless Api::V1::Accounts::MacrosController.ancestors.include?(::KanbanMacrosControllerExtension)
  end
end
