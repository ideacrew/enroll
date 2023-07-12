require 'rails_helper'

RSpec.describe Effective::Datatables::GeneralAgencyPlanDesignOrganizationDatatable, dbclean: :after_each do

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
      let!(:site) { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, EnrollRegistry[:enroll_app].setting(:site_key).item) }
      let!(:general_agency_organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_general_agency_profile, site: site) }
      let(:general_agency_profile) { general_agency_organization.general_agency_profile }
      let!(:general_agency_staff_role) {FactoryBot.build(:general_agency_staff_role, benefit_sponsors_general_agency_profile_id: general_agency_profile.id, aasm_state: 'active')}
      let!(:person_with_ga_staff_role) { general_agency_staff_role.person }
      let!(:user_with_ga_staff_role) { FactoryBot.create(:user, person: person_with_ga_staff_role, roles: ["general_agency_staff"])}

      context 'and belongs to profile' do
        let!(:subject) { described_class.new(profile_id: general_agency_profile.id) }

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