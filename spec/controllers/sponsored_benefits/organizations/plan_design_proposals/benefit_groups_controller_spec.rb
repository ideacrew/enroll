require 'rails_helper'
require "#{SponsoredBenefits::Engine.root}/spec/shared_contexts/sponsored_benefits"

module SponsoredBenefits
  RSpec.describe Organizations::PlanDesignProposals::BenefitGroupsController, type: :controller, dbclean: :around_each  do
    routes { SponsoredBenefits::Engine.routes }
    include_context "set up"

    let!(:person) { FactoryGirl.create(:person, :with_broker_role) }
    let!(:user_with_broker_role) { FactoryGirl.create(:user, person: person ) }
    
    describe "POST #create" do
      before do
        sign_in user_with_broker_role
        person.broker_role.update_attributes(broker_agency_profile_id: plan_design_organization.owner_profile_id)
        post :create, plan_design_proposal_id: plan_design_proposal.id, benefit_group: {kind: 'dental'}
      end

      it "should be success" do
        expect(response).to have_http_status(:success)
      end

      it "should render json" do
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['url']).to eq("some _url")
      end
    end

    describe "DELETE #destroy" do
      before do
        sign_in user_with_broker_role
        person.broker_role.update_attributes(broker_agency_profile_id: plan_design_organization.owner_profile_id)
        delete :destroy, plan_design_proposal_id: plan_design_proposal.id, id: benefit_group.id, benefit_group: {kind: 'dental'}
      end

      it "redirects to new_organizations_plan_design_proposal_plan_selection_path" do
        expect(response).to redirect_to(new_organizations_plan_design_proposal_plan_selection_path(proposal_id: plan_design_proposal.id))
      end
    end
  end
end
