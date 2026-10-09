# frozen_string_literal: true

class AddCategoryAndSalePriceToKanbanProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :kanban_products, :category, :string
    add_column :kanban_products, :sale_price, :decimal, precision: 12, scale: 2

    add_index :kanban_products, [:account_id, :category], name: 'idx_kanban_products_on_account_and_category'
  end
end
