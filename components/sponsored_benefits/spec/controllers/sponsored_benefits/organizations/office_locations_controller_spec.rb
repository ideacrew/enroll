require 'rails_helper'
require "#{SponsoredBenefits::Engine.root}/spec/shared_contexts/sponsored_benefits"

module SponsoredBenefits
  RSpec.describe Organizations::OfficeLocationsController, type: :controller, dbclean: :around_each do
    include_context "set up broker agency profile for BQT, by using configuration settings"

    routes { SponsoredBenefits::Engine.routes }

    def person(trait)
      FactoryGirl.create(:person, trait).tap do |person|
        person.broker_role.update_attributes(broker_agency_profile_id: broker_agency_profile.id.to_s) if trait == :with_broker_role
      end
    end

    def user(person)
      FactoryGirl.create(:user, person: person)
    end

    describe "DELETE" do
      let(:plan_design_org) { plan_design_organization}
      let(:office_location_id) {plan_design_org.office_locations.first.id.to_s}
      let!(:valid_params) { {:id => office_location_id, plan_org_id: plan_design_org.id.to_s }}

      before :each do
        person = person(:with_broker_role)
        sign_in user(person)
      end

      it "should delete office location" do
        get :delete, valid_params
        expect(plan_design_org.reload.office_locations.count).to eq 0
      end

      it "should redirects to edit page" do
        get :delete, valid_params
        url = edit_organizations_plan_design_organization_path(plan_design_org, profile_id: plan_design_org.broker_agency_profile.id.to_s)
        expect(subject).to redirect_to url
      end
    end
  end
end
