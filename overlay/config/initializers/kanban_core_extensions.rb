# frozen_string_literal: true

# Inicializador de extensões do Kanban sobre o Chatwoot Core.
#
# Segue a política arquitetural definida em docs/ARCHITECTURE.md:
# Evita patches em arquivos do core do Chatwoot (Account, Conversation,
# ActionCableListener, AsyncDispatcher, Labels::DestroyService e Events::Types)
# estendendo as classes dinamicamente em tempo de boot (to_prepare).

Rails.application.config.to_prepare do
  # ---------------------------------------------------------------------------
  # 1. Constantes de Eventos do Kanban (Events::Types)
  # ---------------------------------------------------------------------------
  module ::Events::Types
    KANBAN_BOARD_UPDATED   = 'kanban.board.updated' unless const_defined?(:KANBAN_BOARD_UPDATED)
    KANBAN_STAGE_CREATED   = 'kanban.stage.created' unless const_defined?(:KANBAN_STAGE_CREATED)
    KANBAN_STAGE_UPDATED   = 'kanban.stage.updated' unless const_defined?(:KANBAN_STAGE_UPDATED)
    KANBAN_STAGE_DELETED   = 'kanban.stage.deleted' unless const_defined?(:KANBAN_STAGE_DELETED)
    KANBAN_STAGE_REORDERED = 'kanban.stage.reordered' unless const_defined?(:KANBAN_STAGE_REORDERED)
    KANBAN_CARD_CREATED    = 'kanban.card.created' unless const_defined?(:KANBAN_CARD_CREATED)
    KANBAN_CARD_UPDATED    = 'kanban.card.updated' unless const_defined?(:KANBAN_CARD_UPDATED)
    KANBAN_CARD_DELETED    = 'kanban.card.deleted' unless const_defined?(:KANBAN_CARD_DELETED)
    KANBAN_CARD_REORDERED  = 'kanban.card.reordered' unless const_defined?(:KANBAN_CARD_REORDERED)
  end

  # ---------------------------------------------------------------------------
  # 2. Relacionamentos em Account
  # ---------------------------------------------------------------------------
  Account.class_eval do
    has_many :kanban_automation_rules, dependent: :destroy_async unless reflect_on_association(:kanban_automation_rules)
    has_many :kanban_automation_logs, dependent: :destroy_async unless reflect_on_association(:kanban_automation_logs)
    has_many :kanban_product_sources, dependent: :destroy_async unless reflect_on_association(:kanban_product_sources)
    has_many :kanban_products, dependent: :destroy_async unless reflect_on_association(:kanban_products)
  end

  # ---------------------------------------------------------------------------
  # 3. Relacionamento em Conversation
  # ---------------------------------------------------------------------------
  Conversation.class_eval do
    has_many :kanban_cards, dependent: nil unless reflect_on_association(:kanban_cards)
  end

  # ---------------------------------------------------------------------------
  # 4. Listener no AsyncDispatcher
  # ---------------------------------------------------------------------------
  if defined?(AsyncDispatcher) && defined?(KanbanCardListener)
    module ::KanbanAsyncDispatcherExtension
      def listeners
        super + [KanbanCardListener.instance]
      end
    end

    AsyncDispatcher.prepend(::KanbanAsyncDispatcherExtension) unless AsyncDispatcher.ancestors.include?(::KanbanAsyncDispatcherExtension)
  end

  # ---------------------------------------------------------------------------
  # 5. Eventos no ActionCableListener
  # ---------------------------------------------------------------------------
  if defined?(ActionCableListener)
    module ::ActionCableListenerKanbanEvents
      include Events::Types

      KANBAN_EVENT_METHODS = {
        kanban_board_updated: Events::Types::KANBAN_BOARD_UPDATED,
        kanban_stage_created: Events::Types::KANBAN_STAGE_CREATED,
        kanban_stage_updated: Events::Types::KANBAN_STAGE_UPDATED,
        kanban_stage_deleted: Events::Types::KANBAN_STAGE_DELETED,
        kanban_stage_reordered: Events::Types::KANBAN_STAGE_REORDERED,
        kanban_card_created: Events::Types::KANBAN_CARD_CREATED,
        kanban_card_updated: Events::Types::KANBAN_CARD_UPDATED,
        kanban_card_deleted: Events::Types::KANBAN_CARD_DELETED,
        kanban_card_reordered: Events::Types::KANBAN_CARD_REORDERED
      }.freeze

      KANBAN_EVENT_METHODS.each do |method_name, event_name|
        define_method(method_name) do |event|
          broadcast_kanban_event(event, event_name)
        end
      end

      private

      def account_token_for_id(account_id)
        "account_#{account_id}"
      end

      def broadcast_kanban_event(event, event_name)
        ::ActionCableBroadcastJob.perform_later([account_token_for_id(event.data[:account_id])], event_name, event.data)
      end
    end

    ActionCableListener.include(::ActionCableListenerKanbanEvents) unless ActionCableListener.ancestors.include?(::ActionCableListenerKanbanEvents)
  end

  # ---------------------------------------------------------------------------
  # 6. Hook em Labels::DestroyService
  # ---------------------------------------------------------------------------
  if defined?(Labels::DestroyService)
    module ::KanbanLabelsDestroyServiceExtension
      def perform
        super
        remove_kanban_card_labels
      end

      private

      def remove_kanban_card_labels
        return unless defined?(KanbanCard)

        kanban_card_label_taggings.in_batches do |tagging_batch|
          ActsAsTaggableOn::Tagging.where(id: tagging_batch.select(:id)).delete_all
        end
      end

      def kanban_card_label_taggings
        label_taggings_for('KanbanCard').where(taggable_id: KanbanCard.where(account_id: account.id).select(:id))
      end
    end

    Labels::DestroyService.prepend(::KanbanLabelsDestroyServiceExtension) unless Labels::DestroyService.ancestors.include?(::KanbanLabelsDestroyServiceExtension)
  end
end
