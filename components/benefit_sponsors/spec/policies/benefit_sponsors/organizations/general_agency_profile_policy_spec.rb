# frozen_string_literal: true

require 'rails_helper'
# spec for GeneralAgencyProfilePolicy
module BenefitSponsors
  RSpec.describe Organizations::GeneralAgencyProfilePolicy, dbclean: :after_each  do
    let!(:user) { FactoryBot.create(:user) }
    let!(:person) {FactoryBot.create(:person, user: user)}

    context 'access to general agency profile' do
      it 'returns true if admin user and has hbx staff role' do
        user_with_hbx_staff_role = FactoryBot.create(:user, :with_hbx_staff_role)
        FactoryBot.create(:person, user: user_with_hbx_staff_role)
        policy = BenefitSponsors::Organizations::GeneralAgencyProfilePolicy.new(user_with_hbx_staff_role, nil)
        expect(policy.can_read_inbox?).to be true
      end

      it 'returns false if user has no valid role' do
        policy = BenefitSponsors::Organizations::GeneralAgencyProfilePolicy.new(user, nil)
        expect(policy.can_read_inbox?).to be false
      end

      it 'returns true if general agency has staff role' do
        person_with_ga_staff_role = FactoryBot.create(:person, :with_general_agency_staff_role)
        user_with_ga_staff_role = FactoryBot.create(:user, person: person_with_ga_staff_role, roles: ["general_agency_staff"])
        policy = BenefitSponsors::Organizations::GeneralAgencyProfilePolicy.new(user_with_ga_staff_role, nil)

        expect(policy.can_read_inbox?).to be true
      end
    end
  end
end

