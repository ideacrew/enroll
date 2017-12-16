require "rails_helper"

module SponsoredBenefits
  RSpec.describe BenefitSponsorships::PlanDesignEmployerProfilesController, type: :routing do
    describe "routing" do

      it "routes to #index" do
        expect(:get => "/benefit_sponsorships/plan_design_employer_profiles").to route_to("benefit_sponsorships/plan_design_employer_profiles#index")
      end

      it "routes to #new" do
        expect(:get => "/benefit_sponsorships/plan_design_employer_profiles/new").to route_to("benefit_sponsorships/plan_design_employer_profiles#new")
      end

      it "routes to #show" do
        expect(:get => "/benefit_sponsorships/plan_design_employer_profiles/1").to route_to("benefit_sponsorships/plan_design_employer_profiles#show", :id => "1")
      end

      it "routes to #edit" do
        expect(:get => "/benefit_sponsorships/plan_design_employer_profiles/1/edit").to route_to("benefit_sponsorships/plan_design_employer_profiles#edit", :id => "1")
      end

      it "routes to #create" do
        expect(:post => "/benefit_sponsorships/plan_design_employer_profiles").to route_to("benefit_sponsorships/plan_design_employer_profiles#create")
      end

      it "routes to #update via PUT" do
        expect(:put => "/benefit_sponsorships/plan_design_employer_profiles/1").to route_to("benefit_sponsorships/plan_design_employer_profiles#update", :id => "1")
      end

      it "routes to #update via PATCH" do
        expect(:patch => "/benefit_sponsorships/plan_design_employer_profiles/1").to route_to("benefit_sponsorships/plan_design_employer_profiles#update", :id => "1")
      end

      it "routes to #destroy" do
        expect(:delete => "/benefit_sponsorships/plan_design_employer_profiles/1").to route_to("benefit_sponsorships/plan_design_employer_profiles#destroy", :id => "1")
      end

    end
  end
end
