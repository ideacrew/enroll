# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Effective::Datatables::BenefitSponsorsEmployerDatatable, dbclean: :after_each do

  describe '#authorized?' do
    context 'when current user does not exist' do
      let(:user) { nil }

      it 'should not authorize access' do
        expect(subject.authorized?(user, nil, nil, nil)).to eq(false)
      end
    end

    context 'when current user exists without staff role' do
      let(:user) { FactoryBot.create(:user) }

      it 'should not authorize access' do
        expect(subject.authorized?(user, nil, nil, nil)).to eq(false)
      end
    end

    context 'when current user exists with staff role' do
      let!(:user_with_hbx_staff_role) { FactoryBot.create(:user, :with_hbx_staff_role) }
      let!(:person) { FactoryBot.create(:person, user: user_with_hbx_staff_role)}

      it 'should authorize access' do
        expect(subject.authorized?(user_with_hbx_staff_role, nil, nil, nil)).to eq(true)
      end
    end
  end
end
