# frozen_string_literal: true

require 'rails_helper'

RSpec.describe KanbanProduct do
  let(:account) { create(:account) }
  let(:product) { build(:kanban_product, account: account) }

  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(product).to be_valid
    end

    it 'requires sku' do
      product.sku = nil
      expect(product).not_to be_valid
      expect(product.errors[:sku]).to include("can't be blank")
    end

    it 'requires title' do
      product.title = nil
      expect(product).not_to be_valid
      expect(product.errors[:title]).to include("can't be blank")
    end

    it 'requires price to be greater than or equal to 0' do
      product.price = -10
      expect(product).not_to be_valid
      expect(product.errors[:price]).to include('must be greater than or equal to 0')
    end

    it 'enforces sku uniqueness within account' do
      create(:kanban_product, account: account, sku: 'SKU-001')
      duplicate = build(:kanban_product, account: account, sku: 'SKU-001')

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:sku]).to include('has already been taken')
    end

    it 'allows same sku in different accounts' do
      create(:kanban_product, account: account, sku: 'SKU-001')
      other_product = build(:kanban_product, account: create(:account), sku: 'SKU-001')

      expect(other_product).to be_valid
    end
  end

  describe 'pricing and promotions' do
    it 'detects promotion when sale_price is lower than price' do
      product.price = 100.0
      product.sale_price = 80.0
      expect(product.on_sale?).to be(true)
      expect(product.current_price).to eq(80.0)
    end

    it 'uses regular price when not on sale' do
      product.price = 100.0
      product.sale_price = nil
      expect(product.on_sale?).to be(false)
      expect(product.current_price).to eq(100.0)
    end

    it 'formats payload with correct fields' do
      product.price = 200.0
      product.sale_price = 150.0
      payload = product.formatted_payload

      expect(payload[:sku]).to eq(product.sku)
      expect(payload[:on_sale]).to be(true)
      expect(payload[:pricing][:basePrice]).to eq(200.0)
      expect(payload[:pricing][:salePrice]).to eq(150.0)
      expect(payload[:pricing][:pixPrice]).to eq(150.0)
    end
  end

  describe '.search_for' do
    let!(:phone) { create(:kanban_product, account: account, title: 'Smartphone Samsung Galaxy', sku: 'SAMS-01') }
    let!(:case_item) { create(:kanban_product, account: account, title: 'Capa Protetora Silicone', sku: 'CAPA-01') }

    it 'searches by title' do
      results = described_class.search_for(account, 'Galaxy')
      expect(results).to include(phone)
      expect(results).not_to include(case_item)
    end

    it 'searches by sku' do
      results = described_class.search_for(account, 'CAPA')
      expect(results).to include(case_item)
      expect(results).not_to include(phone)
    end
  end
end
