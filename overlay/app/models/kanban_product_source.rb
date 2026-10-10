# frozen_string_literal: true

# == Schema Information
#
# Table name: kanban_product_sources
#
#  id                  :bigint           not null, primary key
#  active              :boolean          default(TRUE), not null
#  feed_url            :text
#  items_count         :integer          default(0), not null
#  last_sync_error     :text
#  last_sync_status    :string           default("pending"), not null
#  last_synced_at      :datetime
#  name                :string           not null
#  source_type         :string           default("google_merchant_xml"), not null
#  sync_interval_hours :integer          default(24), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_id          :bigint           not null
#
# Indexes
#
#  index_kanban_product_sources_on_account_id  (account_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
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
