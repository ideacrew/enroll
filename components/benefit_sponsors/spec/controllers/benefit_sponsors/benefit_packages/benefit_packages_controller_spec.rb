require 'rails_helper'

module BenefitSponsors
  RSpec.describe BenefitPackages::BenefitPackagesController, type: :controller, dbclean: :after_each do

    routes { BenefitSponsors::Engine.routes }

    let!(:site)  { FactoryGirl.create(:benefit_sponsors_site, :with_owner_exempt_organization, :with_benefit_market, :with_benefit_market_catalog_and_product_packages, :cca) }
    let!(:benefit_market) { site.benefit_markets.first }
    let!(:benefit_market_catalog)  { benefit_market.benefit_market_catalogs.first }
    let(:form_class)  { BenefitSponsors::Forms::BenefitPackageForm }
    let!(:user) { FactoryGirl.create :user}
    let!(:organization) { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_dc_employer_profile, site: site) }
    let!(:employer_attestation)     { BenefitSponsors::Documents::EmployerAttestation.new(aasm_state: "approved") }
    let!(:benefit_sponsorship) { FactoryGirl.create(:benefit_sponsors_benefit_sponsorship, organization: organization, profile_id: organization.profiles.first.id, benefit_market: benefit_market, employer_attestation: employer_attestation) }
    let!(:benefit_sponsorship_id) { benefit_sponsorship.id.to_s }
    let!(:benefit_application) { FactoryGirl.create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog, benefit_sponsorship: benefit_sponsorship) }
    let!(:benefit_application_id) { benefit_application.id.to_s }
    let!(:issuer_profile)  { FactoryGirl.create :benefit_sponsors_organizations_issuer_profile }
    let!(:product_package_kind) { :single_issuer }
    let!(:product_package) { benefit_market_catalog.product_packages.where(package_kind: product_package_kind).first }
    let!(:product) { product_package.products.first }

    let(:benefit_package_params) {
      {
        :benefit_application_id => benefit_application.id.to_s,
        :title => "First Benefit Package",
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
          :reference_plan_id => product.id
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
        "0" => {:is_offered => "true", :display_name => "Employee", :contribution_factor => "95.0"},
        "1" => {:is_offered => "true", :display_name => "Spouse", :contribution_factor => "85.0"},
        "2" => {:is_offered => "true", :display_name => "Child", :contribution_factor => "75.0"}
      }
    }


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
        get :new, :benefit_application_id => benefit_application_id, :benefit_sponsorship_id => benefit_sponsorship_id
      end
    end

    # describe "POST create", dbclean: :after_each do

    #   it "should redirect" do
    #     sign_in_and_do_create
    #     expect(response).to have_http_status(:redirect)
    #   end

    #   it "should redirect to benefit packages new" do
    #     sign_in_and_do_create
    #     expect(response.location.include?("benefit_packages/new")).to be_truthy
    #   end

    #   it "should initialize form" do
    #     sign_in_and_do_create
    #     expect(assigns(:benefit_application_form).class).to eq form_class
    #   end

    #   def sign_in_and_do_create
    #     sign_in user
    #     post :create, :benefit_sponsorship_id => benefit_sponsorship_id, :benefit_application_id => benefit_application_id, :benefit_package => benefit_package_params      
    #   end

    # end

  end
end