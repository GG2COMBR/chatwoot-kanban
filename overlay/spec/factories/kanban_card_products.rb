# frozen_string_literal: true

FactoryBot.define do
  factory :kanban_card_product do
    account
    kanban_card { association :kanban_card, account: account }
    name { 'Item Cotado' }
    sku { 'ITEM-01' }
    unit_price { 150.00 }
    quantity { 2 }
    price_type { :pix }
    item_type { :catalog }
    position { 0 }
  end
end
