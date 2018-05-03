require 'rails_helper'

module BenefitMarkets
  RSpec.describe BenefitMarkets::BenefitMarketsController, type: :controller, dbclean: :after_each do
    #def build_site
   #   @site ||= BenefitSponsors::Site.new 
    routes { BenefitMarkets::Engine.routes }

    let(:form_class)  { BenefitMarkets::Forms::BenefitMarket }
    #let!(:site)  { FactoryGirl.create(:sponsored_benefits_site, :with_owner_exempt_organization) }
    let(:shop_kind){:aca_shop}
    let!(:site)          { create(:benefit_sponsors_site, :with_owner_exempt_organization, :with_benefit_market, kind: shop_kind) }
    let(:benefit_market_params) {

      # site_urn: "sdsds",
      # kind: "",
      # title: "",
      # description: "",
      # aca_individual_configuration:{}
      # aca_shop_configuration:{}

    }

    describe "GET new", dbclean: :after_each do
      before do
        get :new, :site_id => benefit_market.site.id
      end
      it "should initialize the form" do
        expect(form_class).to receive(:for_new).and_return(form_class)
      end

      it "should be a success" do
        expect(response).to have_http_status(:success)
      end

      it "should render new template" do
        expect(response).to render_template("new")
      end
    end

    describe "POST create", dbclean: :after_each do
      before do
        post :create, :site_id => site.id,:benefit_market => benefit_market_params
      end

      it "should redirect" do
        expect(response).to have_http_status(:redirect)
      end

      context "when create fails" do

        it "should redirect to new" do
          expect(response).to render_template("new")
        end

        it "should return error messages" do
          expect(flash[:error]).to match(//)
        end
      end

    end

    describe "GET edit", dbclean: :after_each do
      let(:benefit_market) { FactoryGirl.create(:benefit_markets_benefit_market, :with_site) }

      before do
        put :edit, :site_id => site.id,:benefit_market_id => benefit_market.id
      end

      it "should be a success" do
        expect(response).to have_http_status(:success)
      end

      it "should render edit template" do
        expect(response).to render_template("edit")
      end

      it "should initialize form" do
        expect(form_class).to respond_to(:for_edit)
      end

    end

    describe "POST update" do

      let(:benefit_market) { FactoryGirl.create(:benefit_markets_benefit_market, :with_site) }

      before do
        patch :update, :site_id => site.id,:benefit_market_id => benefit_market.id
      end

      it "should be a success" do
        expect(response).to have_http_status(:success)
      end

      it "should initialize form" do
        expect(assigns(:benefit_market).class).to eq form_class
      end

      it "should redirect to benefit mrkets index" do
        expect(response.location.include?("benefit_markets")).to eq true
      end

      context "when update fails" do

      it "should redirect to edit" do
        expect(response).to render_template("edit")
      end

      it "should return error messages" do
        expect(flash[:error]).to match(//)
      end

    end
    end
  end
end