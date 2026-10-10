# frozen_string_literal: true

FactoryBot.define do
  factory :kanban_reason do
    account
    kanban_board { association :kanban_board, account: account }
    title { 'Preço muito alto' }
    reason_type { :lost }
    active { true }
    position { 0 }
  end
end
