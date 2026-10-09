# frozen_string_literal: true

class KanbanProductSyncJob < ApplicationJob
  queue_as :default

  def perform(source_id)
    source = KanbanProductSource.find_by(id: source_id)
    return unless source&.active?

    KanbanProducts::SyncService.new(source).sync!
  rescue StandardError => e
    Rails.logger.error("[KanbanProductSyncJob] Erro ao sincronizar fonte ##{source_id}: #{e.message}")
  end
end
