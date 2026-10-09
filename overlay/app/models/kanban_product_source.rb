# frozen_string_literal: true

class KanbanProductSource < ApplicationRecord
  belongs_to :account
  has_many :kanban_products, dependent: :nullify

  enum source_type: {
    google_merchant_xml: 'google_merchant_xml',
    csv_upload: 'csv_upload'
  }

  validates :name, presence: true
  validates :source_type, presence: true
  validates :feed_url, presence: true, if: :google_merchant_xml?

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(created_at: :desc) }

  def mark_sync_success!(count)
    update!(
      last_synced_at: Time.current,
      last_sync_status: 'success',
      last_sync_error: nil,
      items_count: count
    )
  end

  def mark_sync_failed!(error_message)
    update!(
      last_synced_at: Time.current,
      last_sync_status: 'failed',
      last_sync_error: error_message.to_s.truncate(1000)
    )
  end
end
