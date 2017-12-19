require 'rails_helper'

module SponsoredBenefits
  RSpec.describe BenefitApplications::BenefitApplicationsController, type: :controller do
    let(:broker_agency_profile) { build(:sponsored_benefits_broker_agency_profile) }
    let(:broker_organization) { create(:sponsored_benefits_organization, broker_agency_profile: broker_agency_profile) }
    let(:sponsorship) { build(:benefit_sponsorship) }
    let(:employer_profile) { build(:shop_cca_employer_profile, benefit_sponsorships: [sponsorship]) }
    let!(:plan_design_organization) { create(:plan_design_organization, broker_agency_profile: broker_agency_profile, plan_design_profile: employer_profile) }
    let(:beginning_of_next_month) { Date.today.next_month.beginning_of_month }
    let(:end_of_month) { Date.today.end_of_month }

    let(:valid_attributes) {
      {
        effective_period: (beginning_of_next_month..(end_of_month + 1.year)),
        open_enrollment_period: (Date.today..end_of_month),
      }
    }

    let(:invalid_attributes) {
      skip("Add a hash of attributes invalid for your model")
    }

    # This should return the minimal set of values that should be in the session
    # in order to pass any filters (e.g. authentication) defined in
    # BenefitApplications::BenefitApplicationsController. Be sure to keep this updated too.
    let(:valid_session) { {} }

    describe "GET #index" do
      it "returns a success response" do
        benefit_application = sponsorship.benefit_applications.create! valid_attributes
        get :index, { benefit_sponsorship_id: sponsorship.id }, valid_session
        expect(response).to be_success
      end
    end

    describe "GET #show" do
      it "returns a success response" do
        benefit_application = BenefitApplications::BenefitApplication.create! valid_attributes
        get :show, {:id => benefit_application.to_param}, valid_session
        expect(response).to be_success
      end
    end

    describe "GET #new" do
      it "returns a success response" do
        get :new, {}, valid_session
        expect(response).to be_success
      end
    end

    describe "GET #edit" do
      it "returns a success response" do
        benefit_application = BenefitApplications::BenefitApplication.create! valid_attributes
        get :edit, {:id => benefit_application.to_param}, valid_session
        expect(response).to be_success
      end
    end

    describe "POST #create" do
      context "with valid params" do
        it "creates a new BenefitApplications::BenefitApplication" do
          expect {
            post :create, {:benefit_applications_benefit_application => valid_attributes}, valid_session
          }.to change(BenefitApplications::BenefitApplication, :count).by(1)
        end

        it "redirects to the created benefit_applications_benefit_application" do
          post :create, {:benefit_applications_benefit_application => valid_attributes}, valid_session
          expect(response).to redirect_to(BenefitApplications::BenefitApplication.last)
        end
      end

      context "with invalid params" do
        it "returns a success response (i.e. to display the 'new' template)" do
          post :create, {:benefit_applications_benefit_application => invalid_attributes}, valid_session
          expect(response).to be_success
        end
      end
    end

    describe "PUT #update" do
      context "with valid params" do
        let(:new_attributes) {
          skip("Add a hash of attributes valid for your model")
        }

        it "updates the requested benefit_applications_benefit_application" do
          benefit_application = BenefitApplications::BenefitApplication.create! valid_attributes
          put :update, {:id => benefit_application.to_param, :benefit_applications_benefit_application => new_attributes}, valid_session
          benefit_application.reload
          skip("Add assertions for updated state")
        end

        it "redirects to the benefit_applications_benefit_application" do
          benefit_application = BenefitApplications::BenefitApplication.create! valid_attributes
          put :update, {:id => benefit_application.to_param, :benefit_applications_benefit_application => valid_attributes}, valid_session
          expect(response).to redirect_to(benefit_application)
        end
      end

      context "with invalid params" do
        it "returns a success response (i.e. to display the 'edit' template)" do
          benefit_application = BenefitApplications::BenefitApplication.create! valid_attributes
          put :update, {:id => benefit_application.to_param, :benefit_applications_benefit_application => invalid_attributes}, valid_session
          expect(response).to be_success
        end
      end
    end

    describe "DELETE #destroy" do
      it "destroys the requested benefit_applications_benefit_application" do
        benefit_application = BenefitApplications::BenefitApplication.create! valid_attributes
        expect {
          delete :destroy, {:id => benefit_application.to_param}, valid_session
        }.to change(BenefitApplications::BenefitApplication, :count).by(-1)
      end

      it "redirects to the benefit_applications_benefit_applications list" do
        benefit_application = BenefitApplications::BenefitApplication.create! valid_attributes
        delete :destroy, {:id => benefit_application.to_param}, valid_session
        expect(response).to redirect_to(benefit_applications_benefit_applications_url)
      end
    end

  end
end
