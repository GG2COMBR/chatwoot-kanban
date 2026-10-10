# frozen_string_literal: true

require 'rails_helper'

RSpec.describe KanbanCardProduct do
  let(:account) { create(:account) }
  let(:card) { create(:kanban_card, account: account) }
  let(:card_product) { build(:kanban_card_product, account: account, kanban_card: card) }

  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(card_product).to be_valid
    end

    it 'requires name' do
      card_product.name = nil
      expect(card_product).not_to be_valid
      expect(card_product.errors[:name]).to include("can't be blank")
    end

    it 'requires sku for catalog items' do
      card_product.item_type = :catalog
      card_product.sku = nil
      expect(card_product).not_to be_valid
      expect(card_product.errors[:sku]).to include("can't be blank")
    end

    it 'allows empty sku for custom items' do
      card_product.item_type = :custom
      card_product.sku = nil
      expect(card_product).to be_valid
    end

    it 'requires unit_price to be >= 0' do
      card_product.unit_price = -5.0
      expect(card_product).not_to be_valid
      expect(card_product.errors[:unit_price]).to include('must be greater than or equal to 0')
    end

    it 'requires quantity to be positive integer' do
      card_product.quantity = 0
      expect(card_product).not_to be_valid
      expect(card_product.errors[:quantity]).to include('must be greater than 0')
    end

    it 'validates account consistency with card' do
      other_card = create(:kanban_card, account: create(:account))
      card_product.kanban_card = other_card

      expect(card_product).not_to be_valid
      expect(card_product.errors[:account_id]).to include('is invalid')
    end
  end

  describe '#subtotal' do
    it 'calculates unit_price times quantity' do
      card_product.unit_price = 49.90
      card_product.quantity = 3

      expect(card_product.subtotal).to eq(149.70)
    end
  end
end
