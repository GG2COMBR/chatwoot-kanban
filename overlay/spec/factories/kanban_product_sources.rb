# frozen_string_literal: true

FactoryBot.define do
  factory :kanban_product_source do
    account
    name { 'Google Merchant Principal' }
    source_type { 'google_merchant_xml' }
    feed_url { 'https://exemplo.com/feed.xml' }
    sync_interval_hours { 24 }
    active { true }
  end
end
