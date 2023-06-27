# frozen_string_literal: true

require 'rails_helper'
# spec for GeneralAgencyProfilePolicy
module BenefitSponsors
  RSpec.describe Organizations::GeneralAgencyProfilePolicy, dbclean: :after_each  do
    let!(:user) { FactoryBot.create(:user) }
    let!(:site) { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let(:general_agency) {FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_general_agency_profile, site: site)}
    let(:general_agency_profile) {general_agency.profiles.first }
    let(:policy){BenefitSponsors::Organizations::GeneralAgencyProfilePolicy.new(user, general_agency_profile)}
    let(:organization_with_hbx_profile)  { site.owner_organization }
    let!(:organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_general_agency_profile, site: site) }
    let(:gap_id) { organization.general_agency_profile.id }
    let(:general_agency_staff_role) { FactoryBot.create(:general_agency_staff_role, benefit_sponsors_general_agency_profile_id: general_agency_profile.id, aasm_state: "active")}
    let!(:person) {FactoryBot.create(:person, user: user)}

    context 'access to general agency profile' do
      it 'returns true if admin user and has hbx staff role' do
        user_with_hbx_staff_role = FactoryBot.create(:user, :with_hbx_staff_role)
        FactoryBot.create(:person, user: user_with_hbx_staff_role)
        policy = BenefitSponsors::Organizations::GeneralAgencyProfilePolicy.new(user_with_hbx_staff_role, general_agency_profile)
        expect(policy.can_read_inbox?).to be true
      end

      it 'returns false if user has no valid role' do
        expect(policy.can_read_inbox?).to be false
      end

      it 'returns true if general agency has staff role' do
        general_agency_staff_role1 = FactoryBot.create(:general_agency_staff_role, aasm_state: 'active', is_primary: true)
        new_user = FactoryBot.create(:user, person: general_agency_staff_role1.person)
        policy = BenefitSponsors::Organizations::GeneralAgencyProfilePolicy.new(new_user, general_agency_staff_role1)

        expect(policy.can_read_inbox?).to be true
      end
    end
  end
end

