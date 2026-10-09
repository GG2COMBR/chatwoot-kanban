# frozen_string_literal: true

class Api::V1::Accounts::KanbanProductSourcesController < Api::V1::Accounts::BaseController
  include KanbanFeatureAuthorization

  before_action :ensure_kanban_products_feature_enabled
  before_action :fetch_source, only: %i[sync destroy]

  def index
    @sources = Current.account.kanban_product_sources.ordered
    render json: {
      sources: @sources.as_json(
        only: %i[
          id name source_type feed_url sync_interval_hours
          last_synced_at last_sync_status last_sync_error
          items_count active created_at updated_at
        ]
      )
    }
  end

  def create
    if params[:file].present?
      source_name = params[:name].presence ||
                    params.dig(:kanban_product_source, :name).presence ||
                    params[:file].original_filename

      @source = Current.account.kanban_product_sources.create!(
        name: source_name,
        source_type: 'csv_upload'
      )

      count = KanbanProducts::SyncService.new(@source).sync_csv_content!(params[:file].read)
      render json: { success: true, source: @source, items_count: count }, status: :created
    else
      @source = Current.account.kanban_product_sources.create!(source_params)
      KanbanProductSyncJob.perform_later(@source.id)
      render json: { success: true, source: @source }, status: :created
    end
  rescue StandardError => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end

  def sync
    if @source.source_type == 'google_merchant_xml'
      KanbanProductSyncJob.perform_later(@source.id)
      render json: { success: true, message: 'Sincronização iniciada em background' }
    else
      render json: { success: false, error: 'Fontes CSV devem ser atualizadas via novo upload' }, status: :bad_request
    end
  end

  def destroy
    @source.destroy!
    head :no_content
  end

  private

  def fetch_source
    @source = Current.account.kanban_product_sources.find(params[:id])
  end

  def source_params
    source_payload = params[:kanban_product_source] || params
    source_payload.permit(
      :name, :source_type, :feed_url, :sync_interval_hours, :active
    )
  end
end
