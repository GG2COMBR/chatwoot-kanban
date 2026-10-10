# frozen_string_literal: true

require 'rails_helper'

RSpec.describe KanbanReason do
  let(:account) { create(:account) }
  let(:kanban_board) { create(:kanban_board, account: account) }
  let(:reason) { build(:kanban_reason, account: account, kanban_board: kanban_board) }

  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(reason).to be_valid
    end

    it 'requires title' do
      reason.title = nil
      expect(reason).not_to be_valid
      expect(reason.errors[:title]).to include("can't be blank")
    end

    it 'requires reason_type' do
      reason.reason_type = nil
      expect(reason).not_to be_valid
      expect(reason.errors[:reason_type]).to include("can't be blank")
    end

    it 'validates account consistency with board' do
      other_account = create(:account)
      reason.kanban_board = create(:kanban_board, account: other_account)

      expect(reason).not_to be_valid
      expect(reason.errors[:account_id]).to include('is invalid')
    end
  end

  describe 'scopes and enums' do
    it 'supports lost and won reason types' do
      reason.reason_type = :lost
      expect(reason).to be_lost

      reason.reason_type = :won
      expect(reason).to be_won
    end

    it 'filters active reasons' do
      active_reason = create(:kanban_reason, account: account, kanban_board: kanban_board, active: true)
      inactive_reason = create(:kanban_reason, account: account, kanban_board: kanban_board, active: false)

      expect(described_class.active).to include(active_reason)
      expect(described_class.active).not_to include(inactive_reason)
    end
  end
end
