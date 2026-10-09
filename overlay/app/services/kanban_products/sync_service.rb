# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'csv'
require 'nokogiri'

module KanbanProducts
  class SyncService
    BATCH_SIZE = 500
    HTTP_TIMEOUT = 30
    MAX_REDIRECTS = 3

    class SyncError < StandardError; end

    attr_reader :source, :account

    def initialize(source)
      @source = source
      @account = source.account
    end

    def sync!
      count = case source.source_type
              when 'google_merchant_xml'
                sync_google_merchant_xml!
              when 'csv_upload'
                raise SyncError, 'CSV source requires uploaded content via sync_csv!'
              else
                raise SyncError, "Unsupported source type: #{source.source_type}"
              end

      source.mark_sync_success!(count)
      count
    rescue StandardError => e
      source.mark_sync_failed!(e.message)
      raise e
    end

    def sync_csv_content!(content)
      records = []
      total_count = 0
      now = Time.current

      clean_content = normalize_csv_content(content)
      col_sep = detect_csv_separator(clean_content)

      CSV.parse(clean_content, headers: true, header_converters: :downcase, col_sep: col_sep) do |row|
        sku = (row['id'] || row['sku'] || row['g:id']).to_s.strip
        title = (row['title'] || row['name'] || row['g:title']).to_s.strip
        next if sku.blank? || title.blank?

        price_raw = (row['price'] || row['g:price']).to_s
        price, currency = parse_price(price_raw)

        sale_price_raw = (row['sale_price'] || row['saleprice'] || row['preco_promocional'] || row['g:sale_price']).to_s
        sale_price, = parse_price(sale_price_raw) if sale_price_raw.present?

        category = (row['category'] || row['product_type'] || row['categoria'] || row['g:product_type'] || row['g:google_product_category']).to_s.strip.presence

        records << {
          account_id: account.id,
          kanban_product_source_id: source.id,
          sku: sku,
          title: title,
          description: (row['description'] || row['g:description']).to_s.strip.presence,
          category: category,
          price: price,
          sale_price: sale_price,
          currency: currency.presence || 'BRL',
          image_url: (row['image_link'] || row['image_url'] || row['g:image_link']).to_s.strip.presence,
          product_url: (row['link'] || row['product_url'] || row['g:link']).to_s.strip.presence,
          brand: (row['brand'] || row['g:brand']).to_s.strip.presence,
          availability: (row['availability'] || row['g:availability']).to_s.strip.presence || 'in_stock',
          active: true,
          created_at: now,
          updated_at: now
        }

        if records.size >= BATCH_SIZE
          upsert_batch!(records)
          total_count += records.size
          records.clear
        end
      end

      if records.any?
        upsert_batch!(records)
        total_count += records.size
      end

      source.mark_sync_success!(total_count)
      total_count
    rescue StandardError => e
      source.mark_sync_failed!(e.message)
      raise e
    end

    def sync_xml_content!(xml_body)
      doc = Nokogiri::XML(xml_body)
      doc.remove_namespaces!

      records = []
      total_count = 0
      now = Time.current

      items = doc.xpath('//channel/item | //feed/entry')
      raise SyncError, 'Nenhum item encontrado no feed XML' if items.empty?

      items.each do |item|
        sku = extract_text(item, 'id').presence
        title = extract_text(item, 'title').presence
        next if sku.blank? || title.blank?

        price_raw = extract_text(item, 'price')
        price, currency = parse_price(price_raw)

        sale_price_raw = extract_text(item, 'sale_price')
        sale_price, = parse_price(sale_price_raw) if sale_price_raw.present?

        category = extract_text(item, 'product_type').presence || extract_text(item, 'google_product_category').presence

        records << {
          account_id: account.id,
          kanban_product_source_id: source.id,
          sku: sku,
          title: title,
          description: extract_text(item, 'description').presence,
          category: category,
          price: price,
          sale_price: sale_price,
          currency: currency.presence || 'BRL',
          image_url: extract_text(item, 'image_link').presence,
          product_url: extract_text(item, 'link').presence,
          brand: extract_text(item, 'brand').presence,
          availability: extract_text(item, 'availability').presence || 'in_stock',
          active: true,
          created_at: now,
          updated_at: now
        }

        if records.size >= BATCH_SIZE
          upsert_batch!(records)
          total_count += records.size
          records.clear
        end
      end

      if records.any?
        upsert_batch!(records)
        total_count += records.size
      end

      source.mark_sync_success!(total_count)
      total_count
    rescue StandardError => e
      source.mark_sync_failed!(e.message)
      raise e
    end

    private

    def sync_google_merchant_xml!
      raise SyncError, 'URL do feed XML não informada' if source.feed_url.blank?

      xml_body = fetch_http_body(source.feed_url)
      sync_xml_content!(xml_body)
    end

    def extract_text(node, field_name)
      node.at_xpath(field_name)&.text&.strip || ''
    end

    def normalize_csv_content(content)
      return '' if content.blank?

      # Força codificação UTF-8 válida e remove byte order mark (BOM)
      utf8_content = content.to_s.force_encoding('UTF-8')
      utf8_content = utf8_content.scrub('') unless utf8_content.valid_encoding?
      utf8_content.sub(/\A\xEF\xBB\xBF/, '')
    end

    def detect_csv_separator(content)
      first_line = content.lines.first.to_s.strip
      return ',' if first_line.blank?

      semicolons = first_line.count(';')
      commas = first_line.count(',')
      tabs = first_line.count("\t")

      if semicolons > commas && semicolons >= tabs
        ';'
      elsif tabs > commas && tabs > semicolons
        "\t"
      else
        ','
      end
    end

    def parse_price(raw_string)
      return [0.0, 'BRL'] if raw_string.blank?

      # Detecta moeda (BRL, USD, EUR, etc.)
      currency = raw_string[/[A-Z]{3}/] || 'BRL'

      # Remove letras e símbolos de moeda
      cleaned = raw_string.gsub(/[^\d.,]/, '').strip

      # Trata formato BR (ex: 1.250,50) ou formato US (ex: 1,250.50)
      if cleaned.include?(',') && cleaned.include?('.')
        cleaned = if cleaned.rindex(',') > cleaned.rindex('.')
                    cleaned.tr('.', '').tr(',', '.')
                  else
                    cleaned.tr(',', '')
                  end
      elsif cleaned.include?(',')
        cleaned = cleaned.tr(',', '.')
      end

      [cleaned.to_f, currency]
    end

    def upsert_batch!(records)
      return if records.empty?

      KanbanProduct.upsert_all(
        records,
        unique_by: :idx_kanban_products_on_account_and_sku,
        update_only: %i[
          kanban_product_source_id
          title
          description
          category
          price
          sale_price
          currency
          image_url
          product_url
          brand
          availability
          active
        ]
      )
    end

    def fetch_http_body(url_string, redirects_remaining = MAX_REDIRECTS)
      raise SyncError, 'Muitos redirecionamentos ao buscar feed' if redirects_remaining.negative?

      uri = URI.parse(url_string)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      http.open_timeout = HTTP_TIMEOUT
      http.read_timeout = HTTP_TIMEOUT

      request = Net::HTTP::Get.new(uri.request_uri)
      request['User-Agent'] = 'Chatwoot-Kanban-FeedSync/1.0'

      response = http.request(request)

      case response
      when Net::HTTPSuccess
        response.body
      when Net::HTTPRedirection
        location = response['location']
        redirected_uri = URI.join(url_string, location).to_s
        fetch_http_body(redirected_uri, redirects_remaining - 1)
      else
        raise SyncError, "Falha HTTP ao obter feed (#{response.code} #{response.message})"
      end
    rescue SocketError, Timeout::Error, Errno::ECONNREFUSED => e
      raise SyncError, "Erro de rede ao conectar ao feed: #{e.message}"
    end
  end
end
