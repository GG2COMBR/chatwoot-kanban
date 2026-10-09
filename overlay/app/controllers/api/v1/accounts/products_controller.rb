# frozen_string_literal: true

class Api::V1::Accounts::ProductsController < Api::V1::Accounts::BaseController
  include KanbanFeatureAuthorization

  before_action :ensure_kanban_products_feature_enabled

  def search
    query = params[:text].presence || params[:sku].presence
    limit = (params[:limit] || 20).to_i.clamp(1, 100)

    products = KanbanProduct.search_for(Current.account, query, limit: limit)

    render json: {
      success: true,
      products: products.map(&:formatted_payload)
    }
  end
end
