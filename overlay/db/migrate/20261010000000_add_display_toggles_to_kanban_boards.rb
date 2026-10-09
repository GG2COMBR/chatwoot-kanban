# frozen_string_literal: true

class AddDisplayTogglesToKanbanBoards < ActiveRecord::Migration[7.0]
  def change
    add_column :kanban_boards, :enable_products, :boolean, default: false, null: false
    add_column :kanban_boards, :show_monetary_values, :boolean, default: false, null: false
  end
end
