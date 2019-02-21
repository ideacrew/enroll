require 'rails_helper'
require "#{SponsoredBenefits::Engine.root}/spec/shared_contexts/sponsored_benefits"
module SponsoredBenefits
  RSpec.describe Organizations::GeneralAgencyProfilesController do
    include_context "set up broker agency profile for BQT, by using configuration settings"
    routes { SponsoredBenefits::Engine.routes }

    let(:user) { FactoryGirl.create(:user)}
    let(:person) { FactoryGirl.create(:person, user: user)}

    before do
      sign_in person.user
    end
    
    describe "GET index" do
      before do
        xhr :get, :index, id: plan_design_organization.id, broker_agency_profile_id: plan_design_organization.owner_profile_id, action_id: "plan_design_#{plan_design_organization.id}"
      end

      it "should initialize form object" do
        expect(assigns(:form).class).to eq SponsoredBenefits::Forms::GeneralAgencyManager
      end

      it "should be success" do
        expect(response).to be_success
      end
    end

    describe "POST assign" do
      before do
        post :assign, id: plan_design_organization.id, broker_agency_profile_id: plan_design_organization.owner_profile_id, general_agency_profile_id: general_agency.id
      end

      it "should initialize form object" do
        expect(assigns(:form).class).to eq SponsoredBenefits::Forms::GeneralAgencyManager
      end

      it "should be redirect to employers tab" do
        expect(subject).to redirect_to(employers_organizations_broker_agency_profile_path(id: plan_design_organization.owner_profile_id))
      end
    end

    describe "POST fire" do
      before do
        post :fire, id: plan_design_organization.id, broker_agency_profile_id: plan_design_organization.owner_profile_id
      end

      it "should initialize form object" do
        expect(assigns(:form).class).to eq SponsoredBenefits::Forms::GeneralAgencyManager
      end

      it "should be redirect to employers tab" do
        expect(subject).to redirect_to(employers_organizations_broker_agency_profile_path(id: plan_design_organization.owner_profile_id))
      end
    end
  end
end
