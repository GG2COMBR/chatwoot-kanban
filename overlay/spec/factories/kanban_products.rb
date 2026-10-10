# frozen_string_literal: true

FactoryBot.define do
  factory :kanban_product do
    account
    sequence(:sku) { |n| "PROD-#{n}" }
    title { 'Notebook Dell Inspiron' }
    price { 3500.00 }
    sale_price { 2999.00 }
    currency { 'BRL' }
    availability { 'in_stock' }
    active { true }
  end
end
