require 'rails_helper'
require "#{SponsoredBenefits::Engine.root}/spec/shared_contexts/sponsored_benefits"

module SponsoredBenefits
  RSpec.describe Organizations::PlanDesignProposals::PlanExportsController, type: :controller, dbclean: :around_each  do
    routes { SponsoredBenefits::Engine.routes }
    include_context "set up"

    let!(:person) { FactoryGirl.create(:person, :with_broker_role) }
    let!(:user_with_broker_role) { FactoryGirl.create(:user, person: person ) }

    describe "POST #create" do
      before do
        plan_design_census_employee
        benefit_application
        person.broker_role.update_attributes(broker_agency_profile_id: plan_design_organization.owner_profile_id)
        sign_in user_with_broker_role
        post :create, plan_design_proposal_id: plan_design_proposal.id, benefit_group: {kind: :health}
      end

      it "should be success" do
        expect(response).to have_http_status(:success)
      end

      it "should set the plan_design_organization instance variable" do
        expect(assigns(:plan_design_organization)).to eq plan_design_organization
      end

      it "should set census_employees instance variable" do
        expect(assigns(:census_employees)).to eq(plan_design_proposal.profile.benefit_sponsorships.first.census_employees)
      end
    end
  end
end
