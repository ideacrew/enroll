# frozen_string_literal: true

require 'rails_helper'
# spec for GeneralAgencyProfilePolicy
module BenefitSponsors
  RSpec.describe Organizations::GeneralAgencyProfilePolicy, dbclean: :after_each  do
    let!(:user) { FactoryBot.create(:user) }
    let(:general_agency_profile) {FactoryBot.create(:general_agency_profile)}
    let(:policy){BenefitSponsors::Organizations::GeneralAgencyProfilePolicy.new(user, general_agency_profile)}
    let!(:site) { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let(:organization_with_hbx_profile)  { site.owner_organization }
    let!(:organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_general_agency_profile, site: site) }
    let(:gap_id) { organization.general_agency_profile.id }
    let(:general_agency_staff_role) { FactoryBot.build(:general_agency_staff_role, benefit_sponsors_general_agency_profile_id: general_agency_profile.id, aasm_state: "active")}
    let!(:person) {FactoryBot.create(:person, user: user)}

    context 'access to general agency profile' do
      it 'returns true if admin user and has hbx staff role' do
        FactoryBot.create(:hbx_staff_role, person: person)
        expect(policy.can_read_inbox?).to be true
      end

      it 'returns false if user has no valid role' do
        expect(policy.can_read_inbox?).to be false
      end

      it 'returns true if general agency has staff role' do
        person.general_agency_staff_roles = [general_agency_staff_role]
        person.save!
        FactoryBot.create(:general_agency_staff_role, benefit_sponsors_general_agency_profile_id: gap_id, person: person)
        expect(policy.can_read_inbox?).to be true
      end
    end
  end
end

