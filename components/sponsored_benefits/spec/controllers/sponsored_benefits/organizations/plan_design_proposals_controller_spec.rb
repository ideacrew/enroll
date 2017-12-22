require 'rails_helper'
module DataTablesAdapter
end
module SponsoredBenefits
  RSpec.describe Organizations::PlanDesignProposalsController, type: :controller, dbclean: :around_each do
    routes { SponsoredBenefits::Engine.routes }
    let(:broker_double) { double(id: '12345') }
    let(:current_person) { double(:current_person) }
    let(:broker_role) { double(:broker_role, broker_agency_profile_id: '12345') }
    let(:datatable) { double(:datatable) }
    let(:customer) { double(:customer, id: '555', sic_code: '1111') }

    let!(:plan_design_organization) { create(:plan_design_organization, customer_profile_id: customer.id, owner_profile_id: '12345', plan_design_proposals: [ plan_design_proposal ], sic_code: customer.sic_code ) }
    let!(:broker_organization) { create(:sponsored_benefits_organization, broker_agency_profile: broker_agency_profile) }
    let(:broker_agency_profile) { build(:sponsored_benefits_broker_agency_profile) }

    let(:sponsorship) { build(:plan_design_benefit_sponsorship,
                        benefit_market: :aca_shop_cca,
                        initial_enrollment_period: initial_enrollment_period,
                        annual_enrollment_period_begin_month_of_year: beginning_of_next_month.month,
                        benefit_applications: [ benefit_application ]
                        ) }
    let(:benefit_application) { build(:plan_design_benefit_application, effective_period: initial_enrollment_period, open_enrollment_period: (Date.today..end_of_month)) }
    let(:cca_employer_profile) { build(:shop_cca_employer_profile, benefit_sponsorships: [ sponsorship ]) }
    let(:plan_design_proposal) { build(:plan_design_proposal, profile: cca_employer_profile) }


    let(:beginning_of_next_month) { Date.today.next_month.beginning_of_month }
    let(:end_of_month) { Date.today.end_of_month }
    let(:initial_enrollment_period) { (beginning_of_next_month..(end_of_month + 1.year)) }

    let(:valid_attributes) {
      {
        title: 'A Proposal Title',
        profile: {
          benefit_sponsorship: {
            initial_enrollment_period: initial_enrollment_period,
            annual_enrollment_period_begin_month_of_year: beginning_of_next_month.month,
            benefit_application: {
              effective_period: initial_enrollment_period,
              open_enrollment_period: (Date.today..end_of_month)
            }
          }
        }
      }
    }


    let(:invalid_attributes) {
      {
        title: 'A Proposal Title',
        profile: {
          benefit_sponsorship: {
            initial_enrollment_period: nil,
            annual_enrollment_period_begin_month_of_year: beginning_of_next_month.month,
            benefit_application: {
              effective_period: ((end_of_month + 1.year)..beginning_of_next_month),
              open_enrollment_period: (beginning_of_next_month.end_of_month..beginning_of_next_month)
            }
          }
        }
      }
    }

    # This should return the minimal set of values that should be in the session
    # in order to pass any filters (e.g. authentication) defined in
    # BenefitApplications::BenefitApplicationsController. Be sure to keep this updated too.
    let(:valid_session) { {} }

    before do
      allow(BrokerAgencyProfile).to receive(:find).with('12345').and_return(broker_double)
      allow(subject).to receive(:current_person).and_return(current_person)
      allow(current_person).to receive(:broker_role).and_return(broker_role)
      allow(subject).to receive(:effective_datatable).and_return(datatable)
    end

    describe "GET #index" do
      it "returns a success response" do
        xhr :get, :index, { plan_design_organization_id: plan_design_organization.id }, valid_session
        expect(response).to be_success
      end
    end

    describe "GET #show" do
      it "returns a success response" do
        get :show, { id: plan_design_proposal.to_param }, valid_session
        expect(response).to be_success
      end
    end

    describe "GET #new" do
      it "returns a success response" do
        get :new, { plan_design_organization_id: plan_design_organization.id }, valid_session
        expect(response).to be_success
      end
    end

    describe "GET #edit" do
      it "returns a success response" do
        get :edit, { id: plan_design_proposal.to_param }, valid_session
        expect(response).to be_success
      end
    end

    describe "POST #create" do
      context "with valid params" do
        it "creates a new Organizations::PlanDesignProposal" do
          expect {
            post :create, { plan_design_organization_id: plan_design_organization.to_param, plan_design_proposal: valid_attributes }, valid_session
          }.to change { plan_design_organization.reload.plan_design_proposals.count }.by(1)
        end

        it "redirects to the created benefit_application" do
          post :create, { plan_design_organization_id: plan_design_organization.to_param, plan_design_proposal: valid_attributes }, valid_session

          expect(response).to redirect_to(plan_design_proposal_path(plan_design_organization.reload.plan_design_proposals.last))
        end
      end

      context "with invalid params" do
        it "returns a success response (i.e. to display the 'new' template)" do
          post :create, { plan_design_organization_id: plan_design_organization.to_param, plan_design_proposal: invalid_attributes}, valid_session
          expect(response).to be_success
        end
      end
    end

    describe "PUT #update" do
      context "with valid params" do
        let(:new_attributes) {
          { title: "New Title" }
        }

        it "updates the requested benefit_application" do
          expect {
            put :update, {:id => plan_design_proposal.to_param, :plan_design_proposal => new_attributes}, valid_session
          }.to change { plan_design_organization.reload.plan_design_proposals.first.title }.to('New Title')
        end

        it "redirects to the benefit_application" do
          benefit_application = sponsorship.benefit_applications.create! valid_attributes
          put :update, {:id => benefit_application.to_param, :benefit_application => valid_attributes}, valid_session
          expect(response).to redirect_to(benefit_application_path(benefit_application))
        end
      end

      context "with invalid params" do
        it "returns a success response (i.e. to display the 'edit' template)" do
          benefit_application = sponsorship.benefit_applications.create! valid_attributes
          put :update, {:id => benefit_application.to_param, :benefit_application => invalid_attributes}, valid_session
          expect(response).to be_success
        end
      end
    end

    describe "DELETE #destroy" do
      it "destroys the requested benefit_application" do
        benefit_application = sponsorship.benefit_applications.create! valid_attributes
        expect {
          delete :destroy, {:id => benefit_application.to_param}, valid_session
        }.to change(BenefitApplications::BenefitApplication, :count).by(-1)
      end

      it "redirects to the benefit_applications list" do
        benefit_application = sponsorship.benefit_applications.create! valid_attributes
        delete :destroy, {:id => benefit_application.to_param}, valid_session
        expect(response).to redirect_to(benefit_sponsorship_benefit_applications(sponsorship))
      end
    end
  end
end
