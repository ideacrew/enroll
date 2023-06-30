# frozen_string_literal: true

require 'rails_helper'
# spec for GeneralAgencyProfilePolicy
module BenefitSponsors
  RSpec.describe PersonPolicy, dbclean: :after_each  do
    context "checks authorization of person role" do
      it "returns true if user is a HBX admin" do
        user = FactoryBot.create(:user)
        FactoryBot.create(:person, user: user)
        FactoryBot.create(:hbx_staff_role, person: user.person)
        policy = BenefitSponsors::PersonPolicy.new(user, nil)
        expect(policy.can_read_inbox?).to be true
      end

      it "returns false if user is not the right person accessing the inbox" do
        user = FactoryBot.create(:user)
        random_user = FactoryBot.create(:user)
        FactoryBot.create(:person, user: user)
        random_person = FactoryBot.create(:person, user: random_user)
        policy = BenefitSponsors::PersonPolicy.new(user, random_person)
        expect(policy.can_read_inbox?).to be false
      end
    end
  end
end
