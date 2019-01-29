require 'rails_helper'
require "#{SponsoredBenefits::Engine.root}/spec/shared_contexts/sponsored_benefits"
USER_ROLES = [:with_hbx_staff_role, :without_hbx_staff_role]

module SponsoredBenefits
  RSpec.describe Organizations::PlanDesignProposals::PlanComparisonsController, type: :controller, dbclean: :around_each  do
    include_context "set up"
    routes { SponsoredBenefits::Engine.routes }

    let!(:person) { FactoryGirl.create(:person, :with_broker_role) }
    let!(:user_with_broker_role) { FactoryGirl.create(:user, person: person ) }

    describe "Get #new", dbclean: :after_each do

      before do
        plan_design_census_employee
        benefit_application
        person.broker_role.update_attributes(broker_agency_profile_id: plan_design_organization.owner_profile_id)
        sign_in user_with_broker_role
        get :new, plan_design_proposal_id: plan_design_proposal.id, sort_by: "skdhjh"
      end

      it "should return success" do
        expect(response).to have_http_status(:success)
      end

      it "dose not assign a qhps" do
        expect(assigns(:qhps)).not_to be nil
      end
    end
  end
end
