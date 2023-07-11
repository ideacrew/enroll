# frozen_string_literal: true

require 'rails_helper'
# spec for GeneralAgencyProfilePolicy
module BenefitSponsors
  RSpec.describe Organizations::GeneralAgencyProfilePolicy, dbclean: :after_each  do
    let(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, EnrollRegistry[:enroll_app].setting(:site_key).item) }
    let(:general_agency) {FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_general_agency_profile, site: site)}
    let(:general_agency_profile) {general_agency.profiles.first }
    let!(:user) { FactoryBot.create(:user) }
    let!(:person) {FactoryBot.create(:person, user: user)}
    let(:person_with_ga_staff_role) { FactoryBot.create(:person, :with_general_agency_staff_role) }
    let(:user_with_ga_staff_role) { FactoryBot.create(:user, person: person_with_ga_staff_role, roles: ["general_agency_staff"]) }

    context 'access to general agency profile' do
      it 'returns true if admin user and has hbx staff role' do
        user_with_hbx_staff_role = FactoryBot.create(:user, :with_hbx_staff_role)
        FactoryBot.create(:person, user: user_with_hbx_staff_role)
        policy = BenefitSponsors::Organizations::GeneralAgencyProfilePolicy.new(user_with_hbx_staff_role, nil)
        expect(policy.can_read_inbox?).to be true
        expect(policy.show?).to be true
      end

      it 'returns false if user has no valid role' do
        policy = BenefitSponsors::Organizations::GeneralAgencyProfilePolicy.new(user, nil)
        expect(policy.can_read_inbox?).to be false
        expect(policy.show?).to be false
      end
    end

    context 'general agency with staff roles' do
      before do
        allow(user_with_ga_staff_role).to receive(:has_general_agency_staff_role?).and_return true
      end

      it 'returns true if user has general agency staff role' do
        person_with_ga_staff_role.general_agency_staff_roles.first.update_attributes(benefit_sponsors_general_agency_profile_id: general_agency_profile.id)
        policy = BenefitSponsors::Organizations::GeneralAgencyProfilePolicy.new(user_with_ga_staff_role, general_agency_profile)

        expect(policy.can_read_inbox?).to be true
        expect(policy.show?).to be true
      end

      it 'returns false if random record is passed' do
        policy = BenefitSponsors::Organizations::GeneralAgencyProfilePolicy.new(user_with_ga_staff_role, person)

        expect(policy.can_read_inbox?).to be false
        expect(policy.show?).to be false
      end
    end
  end
end
