require 'rails_helper'
require "#{SponsoredBenefits::Engine.root}/spec/shared_contexts/sponsored_benefits"

module SponsoredBenefits
  RSpec.describe Organizations::PlanDesignProposals::PlansController, type: :controller, dbclean: :around_each  do
    routes { SponsoredBenefits::Engine.routes }
    include_context "set up"

    let!(:person) { FactoryGirl.create(:person, :with_broker_role) }
    let!(:user_with_broker_role) { FactoryGirl.create(:user, person: person) }

    describe "GET #index" do #todo
      it "returns a success response" do
        plan_design_census_employee
        benefit_application
        person.broker_role.update_attributes(broker_agency_profile_id: plan_design_organization.owner_profile_id)
        sign_in user_with_broker_role
        get :index, plan_design_organization_id: plan_design_organization.id, selected_carrier_level: "single_carrier"
        expect(response).to have_http_status(:success)
      end

      it "should set plans instance variable" do


      end
    end
  end
end
