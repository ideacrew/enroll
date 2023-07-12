# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Effective::Datatables::BrokerApplicantsDataTable, dbclean: :after_each do
  describe '#authorized?' do
    context 'when current user does not exist' do
      let(:user) { nil }

      it 'should not authorize access' do
        expect(subject.authorized?(user, nil, nil, nil)).to eq(false)
      end
    end

    context 'when current user exists without hbx staff role' do
      let(:user) { FactoryBot.create(:user) }

      before do
        allow(user).to receive(:hbx_staff_role?).and_return(false)
      end

      it 'should not authorize access' do
        expect(subject.authorized?(user, nil, nil, nil)).to eq(false)
      end
    end

    context 'when current user exists with hbx staff role' do
      let(:user) { FactoryBot.create(:user) }

      before do
        allow(user).to receive(:hbx_staff_role?).and_return(true)
      end

      it 'should authorize access' do
        expect(subject.authorized?(user, nil, nil, nil)).to eq(true)
      end
    end
  end
end
