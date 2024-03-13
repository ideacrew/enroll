# frozen_string_literal: true

require 'rails_helper'
# spec for GeneralAgencyProfilePolicy
module BenefitSponsors
  RSpec.describe BenefitSponsors::PersonPolicy, dbclean: :after_each  do
    context "checks authorization of person role" do
      let!(:site) { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
      let(:organization_with_hbx_profile)  { site.owner_organization }
      let!(:super_admin_permission) { FactoryBot.create(:permission, :super_admin) }

      it "returns true if user is a HBX admin" do
        user_with_hbx_staff_role = FactoryBot.create(:user, :with_hbx_staff_role)
        FactoryBot.create(:person, user: user_with_hbx_staff_role)
        user_with_hbx_staff_role.person.build_hbx_staff_role(hbx_profile_id: organization_with_hbx_profile.hbx_profile.id)
        user_with_hbx_staff_role.person.hbx_staff_role.permission_id = super_admin_permission.id
        user_with_hbx_staff_role.person.hbx_staff_role.save!
        policy = BenefitSponsors::PersonPolicy.new(user_with_hbx_staff_role, nil)
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
