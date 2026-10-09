# frozen_string_literal: true

class KanbanProductSourcesSchedulerJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    KanbanProductSource.active.where(source_type: 'google_merchant_xml').find_each do |source|
      next if source.feed_url.blank?
      next if source.last_synced_at.present? && source.last_synced_at > source.sync_interval_hours.hours.ago

      KanbanProductSyncJob.perform_later(source.id)
    end
  end
end
