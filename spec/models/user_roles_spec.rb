# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe '#all_active_role_names' do
    let(:user) { FactoryBot.create(:user) }
    let(:person) { double('Person') }

    context 'when person is present' do
      before do
        allow(user).to receive(:person).and_return(person)
        allow(person).to receive(:all_active_role_names).and_return(['Broker', 'Consumer'])
      end

      it 'returns all active roles from the person' do
        expect(user.all_active_role_names).to eq(['Broker', 'Consumer'])
      end

      it 'caches the result to avoid recalculating' do
        expect(person).to receive(:all_active_role_names).once.and_return(['Broker', 'Consumer'])
        2.times { user.all_active_role_names }
      end
    end

    context 'when person is not present' do
      before do
        allow(user).to receive(:person).and_return(nil)
      end

      it 'returns an empty array' do
        expect(user.all_active_role_names).to eq([])
      end
    end
  end
end
