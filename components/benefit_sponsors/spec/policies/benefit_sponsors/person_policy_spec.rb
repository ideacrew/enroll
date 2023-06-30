# frozen_string_literal: true

require 'rails_helper'
# spec for GeneralAgencyProfilePolicy
module BenefitSponsors
  RSpec.describe PersonPolicy, dbclean: :after_each  do
    let!(:user) { FactoryBot.create(:user) }
    let!(:person) {FactoryBot.create(:person, user: user)}
    let!(:user_new) { FactoryBot.create(:user) }
    let!(:person_new) {FactoryBot.create(:person, user: user_new)}

    context "checks authorization of person role" do
      it "returns true if user is a HBX admin" do
        user_with_hbx_staff_role = FactoryBot.create(:user, :with_hbx_staff_role)
        FactoryBot.create(:person, user: user_with_hbx_staff_role)
        policy = BenefitSponsors::Organizations::GeneralAgencyProfilePolicy.new(user_with_hbx_staff_role, nil)
        expect(policy.can_read_inbox?).to be true
      end

      it "returns false if user is not the real person accessing the inbox" do
        policy = BenefitSponsors::PersonPolicy.new(user, person_new)
        expect(policy.can_read_inbox?).to be false
      end
    end
  end
end
