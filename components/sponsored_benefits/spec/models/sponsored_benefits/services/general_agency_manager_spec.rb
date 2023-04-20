# frozen_string_literal: true

require 'rails_helper'
require "#{SponsoredBenefits::Engine.root}/spec/shared_contexts/sponsored_benefits"

RSpec.describe SponsoredBenefits::Services::GeneralAgencyManager do
  include_context "set up broker agency profile for BQT, by using configuration settings"

  let(:subject) { SponsoredBenefits::Services::GeneralAgencyManager.new(form)}

  describe "#assign_general_agency" do
    let(:form) do
      SponsoredBenefits::Forms::GeneralAgencyManager.new(
        plan_design_organization_ids: [plan_design_organization.id],
        general_agency_profile_id: general_agency_profile.id,
        broker_agency_profile_id: broker_agency_profile.id
      )
    end

    before do
      subject.assign_general_agency
    end

    it "should create a new general agency account" do
      plan_design_organization.reload
      expect(plan_design_organization.general_agency_accounts.active.size).to eq 1
    end
  end

  describe "#fire_general_agency" do
    let(:form) do
      SponsoredBenefits::Forms::GeneralAgencyManager.new(
        plan_design_organization_ids: [plan_design_organization_with_assigned_ga.id],
        broker_agency_profile_id: broker_agency_profile.id
      )
    end

    before do
      subject.fire_general_agency
    end

    it "should create a new general agency account" do
      plan_design_organization.reload
      expect(plan_design_organization_with_assigned_ga.general_agency_accounts.active.size).to eq 0
    end
  end

  describe "#set_default_general_agency" do
    let(:form) do
      SponsoredBenefits::Forms::GeneralAgencyManager.new(
        plan_design_organization_ids: [plan_design_organization.id],
        general_agency_profile_id: general_agency_profile.id,
        broker_agency_profile_id: broker_agency_profile.id
      )
    end

    before do
      plan_design_organization_with_assigned_ga.owner_profile_id = form.broker_agency_profile_id
      plan_design_organization_with_assigned_ga.has_active_broker_relationship = true
      plan_design_organization_with_assigned_ga.save!
      subject.set_default_general_agency
    end

    it "should set default general agency" do
      expect(plan_design_organization_with_assigned_ga.general_agency_accounts.first.benefit_sponsrship_general_agency_profile_id).to eq BSON::ObjectId(form.general_agency_profile_id)
    end
  end
end
