# frozen_string_literal: true

class CreateKanbanProductsAndSources < ActiveRecord::Migration[7.0]
  def change
    create_table :kanban_product_sources do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.string :source_type, null: false, default: 'google_merchant_xml'
      t.text :feed_url
      t.integer :sync_interval_hours, default: 24, null: false
      t.datetime :last_synced_at
      t.string :last_sync_status, default: 'pending', null: false
      t.text :last_sync_error
      t.integer :items_count, default: 0, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    create_table :kanban_products do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :kanban_product_source, foreign_key: true, index: true
      t.string :sku, null: false
      t.string :title, null: false
      t.text :description
      t.decimal :price, precision: 12, scale: 2, default: 0.0, null: false
      t.string :currency, default: 'BRL', null: false
      t.text :image_url
      t.text :product_url
      t.string :brand
      t.string :availability, default: 'in_stock', null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :kanban_products, [:account_id, :sku], unique: true, name: 'idx_kanban_products_on_account_and_sku'
    add_index :kanban_products, [:account_id, :active], name: 'idx_kanban_products_on_account_and_active'
    add_index :kanban_products, [:account_id, :title], name: 'idx_kanban_products_on_account_and_title'
  end
end
