# frozen_string_literal: true

module KanbanFeatureAuthorization
  extend ActiveSupport::Concern

  included do
    before_action :ensure_kanban_feature_enabled
  end

  private

  def ensure_kanban_feature_enabled
    raise Pundit::NotAuthorizedError unless Current.account&.feature_enabled?('kanban')
  end

  def ensure_kanban_products_feature_enabled
    raise Pundit::NotAuthorizedError unless Current.account&.feature_enabled?('kanban_products')
  end
end
