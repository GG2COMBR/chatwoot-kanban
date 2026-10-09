class KanbanProducts::SearchClient
  include HTTParty

  class ApiError < StandardError; end

  def search(text: nil, sku: nil, price_list: nil, limit: nil)
    base_url = api_base_url
    payload = { query: text, sku: sku, price_list: price_list, limit: limit }.compact
    response = self.class.post(
      "#{base_url}/products/search",
      body: payload.to_json,
      headers: request_headers,
      timeout: 5
    )
    handle_response(response)
  rescue ApiError => e
    raise e
  rescue StandardError => e
    Rails.logger.warn("[KanbanProducts::SearchClient] Connection failed: #{e.message}")
    raise ApiError, "Falha na comunicacao com a API de produtos: #{e.message}"
  end

  private

  def api_base_url
    ENV['KANBAN_PRODUCTS_API_URL'].presence ||
      GlobalConfigService.load('KANBAN_PRODUCTS_API_URL', 'https://produtos-api.sobraltec.com.br')
  end

  def request_headers
    {
      'Content-Type' => 'application/json',
      'X-Agent-Token' => GlobalConfigService.load('KANBAN_PRODUCTS_API_TOKEN', '')
    }
  end

  def handle_response(response)
    raise ApiError, "Products API error: #{response.code}" unless response.success?

    response.parsed_response
  end
end
