# frozen_string_literal: true

require 'rails_helper'

RSpec.describe KanbanProductSource do
  let(:account) { create(:account) }
  let(:source) { build(:kanban_product_source, account: account) }

  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(source).to be_valid
    end

    it 'requires name' do
      source.name = nil
      expect(source).not_to be_valid
      expect(source.errors[:name]).to include("can't be blank")
    end

    it 'requires feed_url for google_merchant_xml' do
      source.source_type = :google_merchant_xml
      source.feed_url = nil
      expect(source).not_to be_valid
      expect(source.errors[:feed_url]).to include("can't be blank")
    end

    it 'allows empty feed_url for csv_upload' do
      source.source_type = :csv_upload
      source.feed_url = nil
      expect(source).to be_valid
    end
  end

  describe 'sync status transitions' do
    let(:persisted_source) { create(:kanban_product_source, account: account) }

    it 'marks sync as successful' do
      persisted_source.mark_sync_success!(150)

      expect(persisted_source.last_sync_status).to eq('success')
      expect(persisted_source.items_count).to eq(150)
      expect(persisted_source.last_synced_at).to be_present
      expect(persisted_source.last_sync_error).to be_nil
    end

    it 'marks sync as failed' do
      persisted_source.mark_sync_failed!('Falha de rede ao obter feed')

      expect(persisted_source.last_sync_status).to eq('failed')
      expect(persisted_source.last_sync_error).to eq('Falha de rede ao obter feed')
      expect(persisted_source.last_synced_at).to be_present
    end
  end
end
