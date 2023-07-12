require 'rails_helper'
require "#{SponsoredBenefits::Engine.root}/spec/shared_contexts/sponsored_benefits"

RSpec.describe Effective::Datatables::GeneralAgencyPlanDesignOrganizationDatatable, dbclean: :after_each do
  include_context "set up broker agency profile for BQT, by using configuration settings"

  describe '#authorized?' do

    context 'when current user does not exist' do
      let(:user) { nil }

      it 'should not authorize access' do
        expect(subject.authorized?(user, nil, nil, nil)).to eq(false)
      end
    end

    context 'hbx staff role' do
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

    context 'when current user exists with general agency staff role' do
      let!(:ga_profile_id) { general_agency_profile.id }
      let!(:general_agency_staff_role) do
        person.general_agency_staff_roles << ::GeneralAgencyStaffRole.new(benefit_sponsors_general_agency_profile_id: ga_profile_id, aasm_state: 'active', npn: '1234567')
        person.save!
        person.general_agency_staff_roles.first
      end
      let!(:person) { FactoryBot.create(:person) }
      let!(:user_with_ga_staff_role) { FactoryBot.create(:user, person: person, roles: ["general_agency_staff"])}

      context 'and belongs to profile' do
        let!(:subject) { described_class.new(profile_id: ga_profile_id) }

        it 'should authorize access' do
          expect(subject.authorized?(user_with_ga_staff_role.reload, nil, nil, nil)).to eq(true)
        end
      end

      context 'and does not belongs to profile' do
        let!(:subject) { described_class.new(profile_id: "test") }

        it 'should not authorize access' do
          expect(subject.authorized?(user_with_ga_staff_role.reload, nil, nil, nil)).to eq(false)
        end
      end
    end
  end
end