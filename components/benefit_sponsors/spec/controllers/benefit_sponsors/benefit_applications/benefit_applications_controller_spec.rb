require 'rails_helper'

module BenefitSponsors
  RSpec.describe BenefitApplications::BenefitApplicationsController, type: :controller, dbclean: :after_each do

    routes { BenefitSponsors::Engine.routes }

    let(:current_effective_date)  { TimeKeeper.date_of_record }
    let(:site)                { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let!(:benefit_market_catalog) { create(:benefit_markets_benefit_market_catalog, :with_product_packages,
                                            benefit_market: benefit_market,
                                            title: "SHOP Benefits for #{current_effective_date.year}",
                                            application_period: (current_effective_date.beginning_of_year..current_effective_date.end_of_year))
                                          }
    let(:benefit_market)      { site.benefit_markets.first }
    let!(:product_package) { benefit_market_catalog.product_packages.first }

    let!(:rating_area)   { FactoryGirl.create_default :benefit_markets_locations_rating_area }
    let!(:service_area)  { FactoryGirl.create_default :benefit_markets_locations_service_area }
    let!(:security_question)  { FactoryGirl.create_default :security_question }

    let(:form_class)  { BenefitSponsors::Forms::BenefitApplicationForm }
    let(:person) { FactoryGirl.create(:person) }
    let!(:person1) { FactoryGirl.create(:person, :with_broker_role) }
    let!(:user_with_broker_role) { FactoryGirl.create(:user, person: person1 ) }
    let!(:broker_organization)                  { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }
    let!(:user) { FactoryGirl.create_default :user, person: person}
    let(:organization) { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let!(:employer_attestation)     { BenefitSponsors::Documents::EmployerAttestation.new(aasm_state: "approved") }
    let(:benefit_sponsorship) do
      FactoryGirl.create(
        :benefit_sponsors_benefit_sponsorship,
        :with_rating_area,
        :with_service_areas,
        supplied_rating_area: rating_area,
        service_area_list: [service_area],
        organization: organization,
        profile_id: organization.profiles.first.id,
        benefit_market: site.benefit_markets[0],
        employer_attestation: employer_attestation) 
    end
    let(:benefit_sponsorship_id) { benefit_sponsorship.id.to_s }
    let(:effective_period_start_on) { TimeKeeper.date_of_record.end_of_month + 1.day + 1.month }
    let(:effective_period_end_on)   { effective_period_start_on + 1.year - 1.day }
    let(:open_enrollment_period_start_on) { effective_period_start_on.prev_month }
    let(:open_enrollment_period_end_on)   { open_enrollment_period_start_on + 9.days }


    let(:benefit_application_params) {

      {
        :start_on => effective_period_start_on,
        :end_on => effective_period_end_on,
        :fte_count => "5",
        :pte_count => "5",
        :msp_count => "5",
        :open_enrollment_start_on => open_enrollment_period_start_on,
        :open_enrollment_end_on => open_enrollment_period_end_on,
        :benefit_sponsorship_id => benefit_sponsorship_id
      }
    }

    shared_context "shared_stuff", :shared_context => :metadata do
      let(:effective_period)                { effective_period_start_on..effective_period_end_on }
      let(:open_enrollment_period)          { open_enrollment_period_start_on..open_enrollment_period_end_on }

      let(:params) {
        {
          recorded_rating_area: rating_area,
          recorded_service_areas: [service_area],
          effective_period: effective_period,
          open_enrollment_period: open_enrollment_period,
          fte_count: "5",
          pte_count: "5",
          msp_count: "5",
        }
      }

      let(:ben_app)       { benefit_sponsorship.benefit_applications.build(params) }
    end

    before do
      TimeKeeper.set_date_of_record_unprotected!(Date.today)
      benefit_sponsorship.benefit_market.site_urn = site.site_key
      benefit_sponsorship.save
    end

    describe "GET new", dbclean: :after_each do
      include_context 'shared_stuff'

      it "should initialize the form" do
        [user, user_with_broker_role].each do |login_user|
          sign_in_and_do_new(login_user)
          expect(assigns(:benefit_application_form).class).to eq form_class
        end
      end

      it "should be a success" do
        [user, user_with_broker_role].each do |login_user|
          sign_in_and_do_new(login_user)
          expect(response).to have_http_status(:success)
        end
      end

      it "should render new template" do
        [user, user_with_broker_role].each do |login_user|
          sign_in_and_do_new(login_user)
          expect(response).to render_template("new")
        end
      end

      def sign_in_and_do_new(user)
        sign_in user
        get :new, :benefit_sponsorship_id => benefit_sponsorship_id
      end
    end

    describe "POST create", dbclean: :after_each do
      include_context 'shared_stuff'

      it "should redirect" do
        [user, user_with_broker_role].each do |login_user|
          sign_in_and_do_create(login_user)
          expect(response).to have_http_status(:redirect)
        end
      end

      it "should redirect to benefit packages new" do
        [user, user_with_broker_role].each do |login_user|
          sign_in_and_do_create(login_user)
          expect(response.location.include?("benefit_packages/new")).to be_truthy
        end
      end

      it "should initialize form" do
        [user, user_with_broker_role].each do |login_user|
          sign_in_and_do_create(login_user)
          expect(assigns(:benefit_application_form).class).to eq form_class
        end
      end

      context "when create fails" do

        before do
          benefit_application_params.merge!({
            open_enrollment_end_on: nil
          })
        end

        it "should redirect to new" do
          [user, user_with_broker_role].each do |login_user|
            sign_in_and_do_create(login_user)
            expect(response).to render_template("new")
          end
        end

        it "should return error messages" do
          [user, user_with_broker_role].each do |login_user|
            sign_in_and_do_create(login_user)
            expect(flash[:error]).to match(/Open enrollment end on can't be blank/)
          end
        end
      end

      def sign_in_and_do_create(user)
        sign_in user
        post :create, :benefit_sponsorship_id => benefit_sponsorship_id, :benefit_application => benefit_application_params
      end
    end

    describe "GET edit", dbclean: :after_each do
      include_context 'shared_stuff'

      before do
        ben_app.save
      end

      it "should be a success" do
        [user, user_with_broker_role].each do |login_user|
          sign_in login_user
          xhr :get, :edit, :benefit_sponsorship_id => benefit_sponsorship_id, id: ben_app.id.to_s, :benefit_application => benefit_application_params
          expect(response).to have_http_status(:success)
        end
      end

      it "should render edit template" do
        [user, user_with_broker_role].each do |login_user|
          sign_in login_user
          xhr :get, :edit, :benefit_sponsorship_id => benefit_sponsorship_id, id: ben_app.id.to_s, :benefit_application => benefit_application_params
          expect(response).to render_template("edit")
        end
      end

      it "should initialize form" do
        [user, user_with_broker_role].each do |login_user|
          sign_in login_user
          xhr :get, :edit, :benefit_sponsorship_id => benefit_sponsorship_id, id: ben_app.id.to_s, :benefit_application => benefit_application_params
          expect(form_class).to respond_to(:for_edit)
        end
      end
    end

    describe "POST update" do
      include_context 'shared_stuff'

      before do
        benefit_sponsorship.benefit_applications = [ben_app]
        ben_app.save
      end

      it "should be a success" do
        [user, user_with_broker_role].each do |login_user|
          sign_in_and_do_update(login_user)
          # expect(response).to have_http_status(:success)
        end
      end

      it "should initialize form" do
        [user, user_with_broker_role].each do |login_user|
          sign_in_and_do_update(login_user)
          expect(assigns(:benefit_application_form).class).to eq form_class
        end
      end

      it "should redirect to benefit packages index" do
        [user, user_with_broker_role].each do |login_user|
          sign_in_and_do_update(login_user)
          expect(response.location.include?("benefit_packages")).to be_truthy
        end
      end

      context "when update fails" do

        before do
          benefit_application_params.merge!({
            open_enrollment_end_on: nil
          })
        end

        it "should redirect to edit" do
          [user, user_with_broker_role].each do |login_user|
            sign_in_and_do_update(login_user)
            expect(response).to render_template("edit")
          end
        end

        it "should return error messages" do
          [user, user_with_broker_role].each do |login_user|
            sign_in_and_do_update(login_user)
            expect(flash[:error]).to match(/Open enrollment end on can't be blank/)
          end
        end
      end

      def sign_in_and_do_update(user)
        sign_in user
        xhr :put, :update, :id => ben_app.id.to_s, :benefit_sponsorship_id => benefit_sponsorship_id, :benefit_application => benefit_application_params
      end
    end

    describe "POST publish" do

      include_context 'shared_stuff'

      let!(:benefit_application) {
        application = FactoryGirl.create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog, benefit_sponsorship: benefit_sponsorship)
        application.benefit_sponsor_catalog.save!
        application
      }
      let!(:benefit_package) { FactoryGirl.create(:benefit_sponsors_benefit_packages_benefit_package, benefit_application: benefit_application, product_package: product_package) }

      before do
        benefit_sponsorship.update_attributes(:profile_id => benefit_sponsorship.organization.profiles.first.id)
      end

      def sign_in_and_submit_application(user)
        sign_in user
        post :submit_application, :benefit_application_id => benefit_application.id.to_s, :benefit_sponsorship_id => benefit_sponsorship_id
      end

      context "benefit application published sucessfully" do
        it "should redirect with success message" do
          [user, user_with_broker_role].each do |login_user|
            sign_in_and_submit_application(login_user)
            expect(flash[:notice]).to eq "Plan Year successfully published."
          end
        end
      end

      context "benefit application published sucessfully but with warning" do

        before do
          allow_any_instance_of(BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService).to receive_message_chain('non_owner_employee_present?').and_return(false)
        end

        it "should redirect with success message" do
          [user, user_with_broker_role].each do |login_user|
            sign_in login_user
            xhr :post, :submit_application, :benefit_application_id => benefit_application.id.to_s, :benefit_sponsorship_id => benefit_sponsorship_id
            expect(flash[:notice]).to eq "Plan Year successfully published."
            expect(flash[:error]).to eq "<li>Warning: You have 0 non-owner employees on your roster. In order to be able to enroll under employer-sponsored coverage, you must have at least one non-owner enrolled. Do you want to go back to add non-owner employees to your roster?</li>"
          end
        end
      end

      context "benefit application is not submitted due to warnings" do

        before :each do
          allow_any_instance_of(BenefitSponsors::Organizations::AcaShopCcaEmployerProfile).to receive(:is_primary_office_local?).and_return(false)
        end

        it "should display warnings" do
          [user, user_with_broker_role].each do |login_user|
            sign_in login_user
            xhr :post, :submit_application, :benefit_application_id => benefit_application.id.to_s, :benefit_sponsorship_id => benefit_sponsorship_id
            have_http_status(:success)
          end
        end
      end

      context "benefit application is not submitted" do
        let!(:benefit_application) { FactoryGirl.create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog, benefit_sponsorship: benefit_sponsorship, aasm_state: :denied) }

        it "should redirect with errors" do
          [user, user_with_broker_role].each do |login_user|
            sign_in login_user
            xhr :post, :submit_application, :benefit_application_id => benefit_application.id.to_s, :benefit_sponsorship_id => benefit_sponsorship_id
            expect(flash[:error]).to match(/Plan Year failed to publish/)
          end
        end
      end
    end

    describe "POST force publish", dbclean: :after_each do
      include_context 'shared_stuff'

      before do
        benefit_sponsorship.benefit_applications = [ben_app]
        ben_app.save
        benefit_sponsorship.update_attributes(:profile_id => benefit_sponsorship.organization.profiles.first.id)
      end

      def sign_in_and_force_submit_application(user)
        sign_in user
        post :force_submit_application, :benefit_application_id => ben_app.id.to_s, :benefit_sponsorship_id => benefit_sponsorship_id
      end

      it "should redirect" do
        [user, user_with_broker_role].each do |login_user|
          sign_in_and_force_submit_application(login_user)
          expect(response).to have_http_status(:redirect)
        end
      end

      # TODO: FIX ME - Add below test after adding business rules engine
      it "should expect benefit application state to be pending" do
        [user, user_with_broker_role].each do |login_user|
          sign_in_and_force_submit_application(login_user)
          ben_app.reload
          # expect(ben_app.aasm_state).to eq :pending
        end
      end

      it "should display errors" do
        [user, user_with_broker_role].each do |login_user|
          sign_in_and_force_submit_application(login_user)
          expect(flash[:error]).to match(/this application is ineligible for coverage/)
        end
      end
    end

    describe "POST revert", dbclean: :after_each do
      include_context 'shared_stuff'
      let!(:benefit_application) { FactoryGirl.create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog, benefit_sponsorship: benefit_sponsorship, aasm_state: :draft) }

      before do
        benefit_sponsorship.update_attributes(:profile_id => benefit_sponsorship.organization.profiles.first.id)
      end

      def sign_in_and_revert(user)
        sign_in user
        post :revert, :benefit_application_id => benefit_application.id.to_s, :benefit_sponsorship_id => benefit_sponsorship_id
      end

      context "when there is no eligible application to revert" do
        it "should redirect" do
          [user, user_with_broker_role].each do |login_user|
            sign_in_and_revert(login_user)
            expect(response).to have_http_status(:success)
          end
        end

        it "should display error message" do
          [user, user_with_broker_role].each do |login_user|
            sign_in_and_revert(login_user)
            expect(flash[:error]).to match(/Plan Year could not be reverted to draft state/)
          end
        end
      end

      context "when there is an eligible application to revert" do
        let!(:benefit_application) { FactoryGirl.create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog, benefit_sponsorship: benefit_sponsorship, aasm_state: :approved) }

        it "should revert benefit application" do
          [user, user_with_broker_role].each do |login_user|
            sign_in_and_revert(login_user)
            expect(ben_app.aasm_state).to eq :draft
          end
        end

        it "should display flash messages" do
          [user, user_with_broker_role].each do |login_user|
            sign_in_and_revert(login_user)
            expect(flash[:notice]).to match(/Plan Year successfully reverted to draft state./)
          end
        end
      end
    end
  end
end
