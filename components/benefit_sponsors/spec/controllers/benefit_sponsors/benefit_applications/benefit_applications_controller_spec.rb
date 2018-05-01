require 'rails_helper'

module BenefitSponsors
  RSpec.describe BenefitApplications::BenefitApplicationsController, type: :controller, dbclean: :after_each do

    routes { BenefitSponsors::Engine.routes }

    let(:form_class)  { BenefitSponsors::Forms::BenefitApplicationForm }
    let(:user) { FactoryGirl.create :user}
    let!(:site)  { FactoryGirl.create(:benefit_sponsors_site, :with_owner_exempt_organization, :with_benefit_market, :with_benefit_market_catalog, :dc) }
    let(:benefit_sponsorship) { FactoryGirl.create(:benefit_sponsors_benefit_sponsorship, :with_organization_dc_profile, benefit_market: site.benefit_markets[0]) }
    let(:benefit_sponsorship_id) { benefit_sponsorship.id.to_s }
    let(:effective_period_start_on) { TimeKeeper.date_of_record.end_of_month + 1.day + 1.month }
    let(:effective_period_end_on)   { effective_period_start_on + 1.year - 1.day }
    let(:open_enrollment_period_start_on) { effective_period_start_on.prev_month }
    let(:open_enrollment_period_end_on)   { open_enrollment_period_start_on + 9.days }

    let(:benefit_application_params) {

      {
        :start_on => effective_period_start_on,
        :end_on => effective_period_end_on,
        :fte_count => "1",
        :pte_count => "1",
        :msp_count => "1",
        :open_enrollment_start_on => open_enrollment_period_start_on,
        :open_enrollment_end_on => open_enrollment_period_end_on,
        :benefit_sponsorship_id => benefit_sponsorship_id
      }
    }

    before do
      benefit_sponsorship.benefit_market.update_attributes!(:site_urn => site.site_key)
    end

    describe "GET new", dbclean: :after_each do

      it "should initialize the form" do
        sign_in_and_do_new
        expect(assigns(:benefit_application_form).class).to eq form_class
      end

      it "should be a success" do
        sign_in_and_do_new
        expect(response).to have_http_status(:success)
      end

      it "should render new template" do
        sign_in_and_do_new
        expect(response).to render_template("new")
      end

      def sign_in_and_do_new
        sign_in user
        get :new, :benefit_sponsorship_id => benefit_sponsorship_id
      end
    end

    describe "POST create", dbclean: :after_each do

      it "should redirect" do
        sign_in_and_do_create
        expect(response).to have_http_status(:redirect)
      end

      it "should redirect to benefit packages new" do
        sign_in_and_do_create
        expect(response.location.include?("benefit_packages/new")).to eq true
      end

      it "should initialize form" do
        sign_in_and_do_create
        expect(assigns(:benefit_application_form).class).to eq form_class
      end

      context "when create fails" do

        before do
          benefit_application_params.merge!({
              open_enrollment_end_on: nil
            })
        end

        it "should redirect to new" do
          sign_in_and_do_create
          expect(response).to render_template("new")
        end

        it "should return error messages" do
          sign_in_and_do_create
          expect(flash[:error]).to match(/Open enrollment end on can't be blank/)
        end
      end

      def sign_in_and_do_create
        sign_in user
        post :create, :benefit_sponsorship_id => benefit_sponsorship_id, :benefit_application => benefit_application_params
      end
    end

    describe "GET edit", dbclean: :after_each do

      let(:effective_period)                { effective_period_start_on..effective_period_end_on }
      let(:open_enrollment_period)          { open_enrollment_period_start_on..open_enrollment_period_end_on }

      let(:params) {
          {
            effective_period: effective_period,
            open_enrollment_period: open_enrollment_period
          }
        }
      let(:ben_app)       { BenefitSponsors::BenefitApplications::BenefitApplication.new(params) }

      before do
        ben_app.save
      end

      it "should be a success" do
        sign_in user
        get :edit, :benefit_sponsorship_id => benefit_sponsorship_id, id: ben_app.id.to_s, :benefit_application => benefit_application_params
        expect(response).to have_http_status(:success)
      end

      it "should render edit template" do
        sign_in user
        get :edit, :benefit_sponsorship_id => benefit_sponsorship_id, id: ben_app.id.to_s, :benefit_application => benefit_application_params
        expect(response).to render_template("edit")
      end

      it "should initialize form" do
        sign_in user
        get :edit, :benefit_sponsorship_id => benefit_sponsorship_id, id: ben_app.id.to_s, :benefit_application => benefit_application_params
        expect(form_class).to respond_to(:for_edit)
      end
    end

    describe "POST update" do
      let(:effective_period)                { effective_period_start_on..effective_period_end_on }
      let(:open_enrollment_period)          { open_enrollment_period_start_on..open_enrollment_period_end_on }

      let(:ben_app_params) {
          {
            effective_period: effective_period,
            open_enrollment_period: open_enrollment_period
          }
        }
      let(:ben_app)       { BenefitSponsors::BenefitApplications::BenefitApplication.new(ben_app_params) }

      before do
        benefit_sponsorship.benefit_applications = [ben_app]
        ben_app.save
      end

      it "should be a success" do
        sign_in_and_do_update
        # expect(response).to have_http_status(:success)
      end

      it "should initialize form" do
        sign_in_and_do_update
        expect(assigns(:benefit_application_form).class).to eq form_class
      end

      it "should redirect to benefit packages index" do
        sign_in_and_do_update
        expect(response.location.include?("benefit_packages")).to eq true
      end

      context "when update fails" do

        before do
          benefit_application_params.merge!({
              open_enrollment_end_on: nil
            })
        end

        it "should redirect to edit" do
          sign_in_and_do_update
          expect(response).to render_template("edit")
        end

        it "should return error messages" do
          sign_in_and_do_update
          expect(flash[:error]).to match(/Open enrollment end on can't be blank/)
        end
      end

      def sign_in_and_do_update
        sign_in user
        post :update, :id => ben_app.id.to_s, :benefit_sponsorship_id => benefit_sponsorship_id, :benefit_application => benefit_application_params
      end
    end
  end
end