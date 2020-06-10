require 'rails_helper'
require File.join(File.dirname(__FILE__), "..", "..", "..", "support/benefit_sponsors_site_spec_helpers")
require File.join(File.dirname(__FILE__), "..", "..", "..", "support/benefit_sponsors_product_spec_helpers")

module BenefitSponsors
  RSpec.describe BenefitPackages::BenefitPackagesController, type: :controller, dbclean: :after_each do

    routes { BenefitSponsors::Engine.routes }

    let!(:benefit_markets_location_rating_area) { FactoryBot.create_default(:benefit_markets_locations_rating_area) }
    let!(:benefit_markets_location_service_area) { FactoryBot.create_default(:benefit_markets_locations_service_area) }
    let!(:security_question)  { FactoryBot.create_default :security_question }
    let(:current_effective_date)  { TimeKeeper.date_of_record }
    let(:site) { ::BenefitSponsors::SiteSpecHelpers.create_site_with_hbx_profile_and_empty_benefit_market }

    let(:benefit_market)      { site.benefit_markets.first }
    let!(:benefit_market_catalog) do
      bmc_id = BenefitSponsors::ProductSpecHelpers.construct_simple_benefit_market_catalog(
        site,
        benefit_market,
        (current_effective_date.beginning_of_year..current_effective_date.end_of_year)
      )
      BenefitMarkets::BenefitMarketCatalog.find(bmc_id)
    end
      
     # create(:benefit_markets_benefit_market_catalog, :with_product_packages,
      #                                      benefit_market: benefit_market,
       #                                     title: "SHOP Benefits for #{current_effective_date.year}",
        #                                    application_period: (current_effective_date.beginning_of_year..current_effective_date.end_of_year))
         #                                 }

    # let!(:benefit_market_catalog)  { benefit_market.benefit_market_catalogs.first }
    let(:organization)        { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let(:employer_profile)    { organization.employer_profile }
    let(:benefit_sponsorship) { employer_profile.add_benefit_sponsorship }
    let!(:benefit_sponsorship_id) { benefit_sponsorship.id.to_s }

    let(:form_class)  { BenefitSponsors::Forms::BenefitPackageForm }
    let(:person) { FactoryBot.create(:person) }
    let!(:user) { FactoryBot.create :user, person: person}
    let!(:employer_attestation)     { BenefitSponsors::Documents::EmployerAttestation.new(aasm_state: "approved") }


    let!(:benefit_application) {
      application = FactoryBot.create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog, benefit_sponsorship: benefit_sponsorship)
      application.benefit_sponsor_catalog.save!
      application
    }
    let!(:benefit_application_id) { benefit_application.id.to_s }
    let!(:issuer_profile)  { FactoryBot.create :benefit_sponsors_organizations_issuer_profile, assigned_site: site}
    let!(:product_package_kind) { :single_issuer }
    let!(:product_package) { benefit_market_catalog.product_packages.where(package_kind: product_package_kind).first }

    let(:product) { product_package.products.first }

    let(:sbc_document) {
      ::Document.new({
        title: 'sbc_file_name', subject: "SBC",
        :identifier=>"urn:openhbx:terms:v1:file_storage:s3:bucket:#{Settings.site.s3_prefix}-enroll-sbc-test#7816ce0f-a138-42d5-89c5-25c5a3408b82"
        })
    }

    let!(:benefit_package) { FactoryBot.create(:benefit_sponsors_benefit_packages_benefit_package, benefit_application: benefit_application, product_package: product_package) }

    let(:benefit_package_params) {
      {
        :benefit_application_id => benefit_application.id.to_s,
        :title => "New Benefit Package",
        :description => "New Model Benefit Package",
        :probation_period_kind => "first_of_month",
        :sponsored_benefits_attributes => sponsored_benefits_params
      }
    }

    let(:sponsored_benefits_params) {
      {
        "0" => {
          :sponsor_contribution_attributes => sponsor_contribution_attributes,
          :product_package_kind => product_package_kind,
          :kind => "health",
          :product_option_choice => issuer_profile.legal_name,
          :reference_plan_id => product.id.to_s
        }
      }
    }

    let(:sponsor_contribution_attributes) {
      {
      :contribution_levels_attributes => contribution_levels_attributes
      }
    }

    let(:contribution_levels_attributes) {
      {
        "0" => {:is_offered => "true", :display_name => "Employee", :contribution_factor => "95", contribution_unit_id: employee_contribution_unit },
        "1" => {:is_offered => "true", :display_name => "Spouse", :contribution_factor => "85", contribution_unit_id: spouse_contribution_unit },
        "2" => {:is_offered => "true", :display_name => "Domestic Partner", :contribution_factor => "75", contribution_unit_id: partner_contribution_unit },
        "3" => {:is_offered => "true", :display_name => "Child Under 26", :contribution_factor => "75", contribution_unit_id: child_contribution_unit }
      }
    }

    let(:contribution_model) { product_package.contribution_model }

    let(:employee_contribution_unit) { contribution_model.contribution_units.where(order: 0).first }
    let(:spouse_contribution_unit) { contribution_model.contribution_units.where(order: 1).first }
    let(:partner_contribution_unit) { contribution_model.contribution_units.where(order: 2).first }
    let(:child_contribution_unit) { contribution_model.contribution_units.where(order: 3).first }
    before do
      issuer_profile.organization.update_attributes!(site_id: site.id)
    end

    describe "GET new" do
      it "should initialize the form" do
        sign_in_and_do_new
        expect(assigns(:benefit_package_form).class).to eq form_class
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
        get :new, params: { benefit_application_id: benefit_application_id, benefit_sponsorship_id: benefit_sponsorship_id }
      end

      it "should route to benefits tab if rates are not present" do
        future_date = TimeKeeper.date_of_record + 1.year
        benefit_application.effective_period = future_date.beginning_of_year..future_date.end_of_year
        benefit_application.save
        sign_in_and_do_new
        expect(response).to redirect_to(profiles_employers_employer_profile_path(assigns(:benefit_package_form).service.employer_profile, :tab=>'benefits'))
      end
    end

    describe "POST create", dbclean: :after_each do

      context "when create is successful" do

        before do
          sign_in_and_do_create
        end

        it "should initialize form" do
          expect(assigns(:benefit_package_form).class).to eq form_class
        end

        it "should redirect" do
          expect(response).to have_http_status(:redirect)
        end

        it "should redirect to benefits tab" do
          expect(response.location.include?("tab=benefits")).to be_truthy
        end

        it "should return flash notices" do
          expect(flash[:notice]).to match(/Benefit Package successfully created/)
        end
      end

      context "when create fails" do

        let(:sponsored_benefits_params) {
          {
            "0" => {
              :sponsor_contribution_attributes => sponsor_contribution_attributes,
              :product_package_kind => product_package_kind,
              :kind => "health",
              :product_option_choice => issuer_profile.legal_name,
              :reference_plan_id => nil
            }
          }
        }

        before do
          sign_in_and_do_create
        end

        it "should redirect to new" do
          sign_in_and_do_create
          expect(response).to render_template("new")
        end

        it "should return error messages" do
          sign_in_and_do_create
          expect(flash[:error]).to match(/Reference plan can't be blank/)
        end
      end

      def sign_in_and_do_create
        sign_in user
        post :create, params: { benefit_sponsorship_id: benefit_sponsorship_id, benefit_application_id: benefit_application_id, benefit_package: benefit_package_params }
      end

    end

    describe "GET edit" do

      before do
        benefit_package.sponsored_benefits.first.reference_product.update_attributes!(:issuer_profile_id => issuer_profile.id)
        benefit_package.reload
      end

      def sign_in_and_do_edit
        sign_in user
        get :edit, params: { benefit_sponsorship_id: benefit_sponsorship_id, benefit_application_id: benefit_application_id, id: benefit_package.id.to_s }
      end

      it "should be a success" do
        sign_in_and_do_edit
        expect(response).to have_http_status(:success)
      end

      it "should initialize form" do
        sign_in_and_do_edit
        expect(form_class).to respond_to(:for_edit)
      end

      it "should render edit template" do
        sign_in_and_do_edit
        expect(response).to render_template("edit")
      end
    end

    describe "GET reference_product_summary details" do

      def sign_in_and_get_ref_prod
        sign_in user
        get :reference_product_summary, params: { :reference_plan_id => product.id, :benefit_application_id => benefit_application_id, :benefit_sponsorship_id => benefit_sponsorship_id }
      end

      before do
        allow(product).to receive(:sbc_document).and_return(sbc_document)
        allow_any_instance_of(BenefitSponsors::Services::BenefitPackageService).to receive(:find_product).and_return(product)
      end

      it "should be a success" do
        sign_in_and_get_ref_prod
        expect(response).to have_http_status(:success)
      end

      it "should initialize form" do
        sign_in_and_get_ref_prod
        expect(form_class).to respond_to(:for_reference_product_summary)
      end
    end

    describe "POST update" do

      let(:contribution_levels) { benefit_package.sponsored_benefits[0].sponsor_contribution.contribution_levels }

      let(:contribution_levels_attributes) {
        {
          "0" => {:id => contribution_levels[0].id.to_s, :is_offered => "true", :display_name => "Employee", :contribution_factor => "95"},
          "1" => {:id => contribution_levels[1].id.to_s, :is_offered => "true", :display_name => "Spouse", :contribution_factor => "85"},
          "2" => {:id => contribution_levels[2].id.to_s, :is_offered => "true", :display_name => "Dependent", :contribution_factor => "75"}
        }
      }

      def sign_in_and_do_update
        sign_in user
        post :update, params: { :benefit_sponsorship_id => benefit_sponsorship_id, :benefit_application_id => benefit_application_id, :id => benefit_package.id.to_s, :benefit_package => benefit_package_params }
      end

      before do
        sanitize_params
      end

      def sanitize_params
        sponsored_benefits_params["0"].merge!({
          id: benefit_package.sponsored_benefits[0].id.to_s
        })
      end

      context "when update is success" do

        it "should be a success" do
          sign_in_and_do_update
          # expect(response).to have_http_status(:success)
        end

        it "should initialize the form" do
          sign_in_and_do_update
          expect(assigns(:benefit_package_form).class).to eq form_class
        end

        it "should redirect to benefit applications" do
          sign_in_and_do_update
          expect(response.location.include?("tab=benefits")).to be_truthy
        end

        it "should redirect to edit dental benefit page" do
          sign_in user
          post :update, params: { :benefit_sponsorship_id => benefit_sponsorship_id, :benefit_application_id => benefit_application_id, :id => benefit_package.id.to_s, :benefit_package => benefit_package_params, add_dental_benefits: "true" }
          expect(response.location.include?("sponsored_benefits/new?kind=dental")).to be_truthy
        end
      end

      context "when update fails" do

        let(:sponsored_benefits_params) {
          {
            "0" => {
              :sponsor_contribution_attributes => sponsor_contribution_attributes,
              :product_package_kind => product_package_kind,
              :kind => "health",
              :product_option_choice => issuer_profile.legal_name,
              :reference_plan_id => nil
            }
          }
        }

        it "should redirect to edit" do
          sign_in_and_do_update
          expect(response).to render_template("edit")
        end

        it "should return error messages" do
          sign_in_and_do_update
          expect(flash[:error]).to match(/Reference plan can't be blank/)
        end
      end
    end
  end
end
