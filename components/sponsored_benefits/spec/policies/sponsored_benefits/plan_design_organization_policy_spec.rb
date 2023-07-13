# frozen_string_literal: true

require "rails_helper"
require "#{SponsoredBenefits::Engine.root}/spec/shared_contexts/sponsored_benefits"

RSpec.describe SponsoredBenefits::PlanDesignOrganizationPolicy, dbclean: :after_each do
  include_context "set up broker agency profile for BQT, by using configuration settings"

  context "when current user does not exist" do
    let!(:user) { nil }
    let!(:subject) { described_class.new(user, {})}

    it "denies access" do
      expect(subject.can_access_employers_tab_via_ga_portal?).to eq(false)
    end
  end

  context "for hbx staff role" do
    context "when current user exists without staff role" do
      let!(:user) { FactoryBot.create(:user) }
      let!(:subject) { described_class.new(user, {})}

      it "denies access" do
        expect(subject.can_access_employers_tab_via_ga_portal?).to eq(false)
      end
    end

    context "when current user exists with staff role" do
      let!(:user_with_hbx_staff_role) { FactoryBot.create(:user, :with_hbx_staff_role) }
      let!(:person) { FactoryBot.create(:person, user: user_with_hbx_staff_role)}
      let!(:subject) { described_class.new(user_with_hbx_staff_role, {})}

      it "allows access" do
        expect(subject.can_access_employers_tab_via_ga_portal?).to eq(true)
      end
    end
  end

  context "for general agency staff role" do
    let!(:profile) { general_agency_profile }
    let!(:general_agency_staff_role) do
      person.general_agency_staff_roles << ::GeneralAgencyStaffRole.new(benefit_sponsors_general_agency_profile_id: profile.id, aasm_state: "active", npn: "1234567")
      person.save!
      person.general_agency_staff_roles.first
    end
    let!(:person) { FactoryBot.create(:person) }
    let!(:user_with_ga_staff_role) { FactoryBot.create(:user, person: person, roles: ["general_agency_staff"])}

    context "when staff belongs to the agency" do
      let!(:subject) { described_class.new(user_with_ga_staff_role, profile)}

      it "allow access" do
        expect(subject.can_access_employers_tab_via_ga_portal?).to eq(true)
      end
    end

    context "when staff does not belong to the agency" do
      let!(:subject) { described_class.new(user_with_ga_staff_role,  nil)}

      it "denies access" do
        expect(subject.can_access_employers_tab_via_ga_portal?).to eq(false)
      end
    end

  end
end
