# frozen_string_literal: true

class KanbanProduct < ApplicationRecord
  belongs_to :account
  belongs_to :kanban_product_source, optional: true

  validates :sku, presence: true
  validates :title, presence: true
  validates :sku, uniqueness: { scope: :account_id }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:title) }

  def self.search_for(account, query, limit: 20)
    scope = where(account_id: account.id).active
    return scope.limit(limit) if query.blank?

    term = "%#{sanitize_sql_like(query.to_s.strip)}%"
    scope.where('sku ILIKE :term OR title ILIKE :term OR brand ILIKE :term OR category ILIKE :term', term: term)
         .order(
           Arel.sql(
             sanitize_sql_array([
               'CASE WHEN sku ILIKE ? THEN 1 WHEN title ILIKE ? THEN 2 ELSE 3 END, title ASC',
               "#{query}%", "#{query}%"
             ])
           )
         )
         .limit(limit)
  end

  def on_sale?
    sale_price.present? && sale_price.positive? && sale_price < price
  end

  def formatted_payload
    effective_sale_price = on_sale? ? sale_price.to_f : nil
    base_price = price.to_f
    current_price = effective_sale_price || base_price

    {
      id: id,
      sku: sku,
      title: title,
      name: title,
      description: description,
      category: category,
      price: current_price,
      regular_price: base_price,
      sale_price: effective_sale_price,
      on_sale: on_sale?,
      currency: currency,
      image_url: image_url,
      imageUrl: image_url,
      product_url: product_url,
      brand: brand,
      availability: availability,
      stockQuantity: availability == 'in_stock' ? 999 : 0,
      pricing: {
        basePrice: base_price,
        salePrice: effective_sale_price,
        pixPrice: current_price,
        onSale: on_sale?
      }
    }
  end
end
