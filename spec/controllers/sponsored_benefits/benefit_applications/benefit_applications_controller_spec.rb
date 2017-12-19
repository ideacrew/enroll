require 'rails_helper'

module SponsoredBenefits
  module BenefitApplications
    RSpec.describe BenefitApplicationsController, type: :controller, db_clean: :around_each do
      routes { SponsoredBenefits::Engine.routes }

      let(:broker_agency_profile) { build(:sponsored_benefits_broker_agency_profile) }
      let(:broker_organization) { create(:sponsored_benefits_organization, broker_agency_profile: broker_agency_profile) }
      let(:sponsorship) { build(:benefit_sponsorship) }
      let(:cca_employer_profile) { build(:shop_cca_employer_profile, benefit_sponsorships: [sponsorship]) }
      let!(:plan_design_organization) { create(:plan_design_organization, broker_agency_profile: broker_agency_profile, plan_design_profile: cca_employer_profile) }
      let(:beginning_of_next_month) { Date.today.next_month.beginning_of_month }
      let(:end_of_month) { Date.today.end_of_month }

      let(:valid_attributes) {
        {
          effective_period: (beginning_of_next_month..(end_of_month + 1.year)),
          open_enrollment_period: (Date.today..end_of_month),
        }
      }

      let(:benefit_application) { sponsorship.benefit_applications.create! valid_attributes }
      let(:invalid_attributes) {
        {
          effective_period: ((end_of_month + 1.year)..beginning_of_next_month),
          open_enrollment_period: (beginning_of_next_month..beginning_of_next_month.end_of_month)
        }
      }

      # This should return the minimal set of values that should be in the session
      # in order to pass any filters (e.g. authentication) defined in
      # BenefitApplications::BenefitApplicationsController. Be sure to keep this updated too.
      let(:valid_session) { {} }

      describe "GET #index" do
        it "returns a success response" do
          get :index, { benefit_sponsorship_id: sponsorship.id }, valid_session
          expect(response).to be_success
        end
      end

      describe "GET #show" do
        it "returns a success response" do
          get :show, { benefit_sponsorship_id: sponsorship.id, id: benefit_application.to_param }, valid_session
          expect(response).to be_success
        end
      end

      describe "GET #new" do
        it "returns a success response" do
          get :new, { benefit_sponsorship_id: sponsorship.id }, valid_session
          expect(response).to be_success
        end
      end

      describe "GET #edit" do
        it "returns a success response" do
          benefit_application = sponsorship.benefit_applications.create! valid_attributes
          get :edit, { benefit_sponsorship_id: sponsorship.id, id: benefit_application.to_param }, valid_session
          expect(response).to be_success
        end
      end

      describe "POST #create" do
        context "with valid params" do
          it "creates a new BenefitApplications::BenefitApplication" do
            expect {
              post :create, { benefit_sponsorship_id: sponsorship.id, benefit_application: valid_attributes}, valid_session
            }.to change { sponsorship.reload.benefit_applications.count }.by(1)
          end

          it "redirects to the created benefit_application" do
            post :create, { benefit_sponsorship_id: sponsorship.id, benefit_application: valid_attributes}, valid_session

            expect(response).to redirect_to(benefit_application_path(sponsorship.reload.benefit_applications.last))
          end
        end

        context "with invalid params" do
          it "returns a success response (i.e. to display the 'new' template)" do
            post :create, { benefit_sponsorship_id: sponsorship.id, benefit_application: invalid_attributes}, valid_session
            expect(response).to be_success
          end
        end
      end

      describe "PUT #update" do
        context "with valid params" do
          let(:new_attributes) {
            { open_enrollment_period: (Date.today+3.days..end_of_month) }
          }

          it "updates the requested benefit_application" do
            benefit_application = sponsorship.benefit_applications.create! valid_attributes
            expect {
              put :update, {:id => benefit_application.to_param, :benefit_application => new_attributes}, valid_session
            }.to change { sponsorship.reload.benefit_applications.first.open_enrollment_period.begin }.by(3.days)
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
end
