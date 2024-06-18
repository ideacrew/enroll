# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Effective::Datatables::UserAccountDatatable do
  describe '#all_roles' do
    let(:user) { FactoryBot.create(:user) }

    context 'when the user has active roles' do
      before do
        allow(user).to receive(:all_active_role_names).and_return(['admin', 'editor'])
      end

      it 'returns a comma-separated string of active roles' do
        expect(subject.all_roles(user)).to eq('admin, editor')
      end
    end

    context 'when the user has no active roles' do
      before do
        allow(user).to receive(:all_active_role_names).and_return([])
      end

      it 'returns an empty string' do
        expect(subject.all_roles(user)).to eq('')
      end
    end
  end
end
