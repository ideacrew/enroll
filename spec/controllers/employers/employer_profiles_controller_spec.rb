require 'rails_helper'

RSpec.describe Employers::EmployerProfilesController, :kind => :controller do
  describe "create employer" do
    login_user 
    include_context "BradyWork"
    let(:organization) { mikes_organization }
    let(:employer_profile) { mikes_employer }
    let(:plan_year) { mikes_plan_year }
    let(:benefit_group) { mikes_benefit_group }
    let(:relationship_benefit) { FactoryGirl.build(:relationship_benefit) }
    let(:office_location) { mikes_office_location }

    it "create successful" do
      relationship_benefit_params = relationship_benefit.attributes.to_hash
      benefit_group_params = benefit_group.attributes.to_hash
      benefit_group_params[:relationship_benefits_attributes] = {"0" => relationship_benefit_params}
      plan_year_params = plan_year.attributes.to_hash
      plan_year_params[:benefit_groups_attributes] = {"0" => benefit_group_params}
      employer_profile_params = employer_profile.attributes.to_hash
      employer_profile_params[:plan_years_attributes] = {"0" => plan_year_params}
      employer_profile_params[:fein] = "123321456"
      employer_profile_params[:dba] = "dba"
      employer_profile_params[:legal_name] = "legal name"
      organization_params = organization.attributes.to_hash
      organization_params[:employer_profile_attributes] = employer_profile_params
      office_location_params = office_location.attributes.to_hash
      office_location_params[:phone_attributes] = mikes_work_phone.attributes.to_hash
      office_location_params[:address_attributes] = mikes_work_addr.attributes.to_hash
      organization_params[:office_locations_attributes] = {"0" => office_location_params}

      organization.destroy
      org_count = Organization.count
      post :create, organization: organization_params
      expect(Organization.count).to eq (org_count + 1)
      expect(controller.flash.now[:notice]).to eq "Employer successfully created." 
    end
  end

  describe "GET index" do
    login_user 
    include_context "BradyWork"

    it "returns http success" do 
      get :index
      expect(response).to have_http_status(:success)
    end

    it "returns results with name search" do
      mikes_organization
      mikes_employer
      og = FactoryGirl.create(:organization, :legal_name => "ss corp bb")
      ep = FactoryGirl.create(:employer_profile, :organization => og)

      get :index, q: "corp"
      expect(assigns(:employer_profiles)).to eq [ep]
    end

    it "returns results success" do
      Organization.destroy_all
      og = FactoryGirl.create(:organization, :legal_name => "ss corp bb")
      ep = FactoryGirl.create(:employer_profile, :organization => og)
      FactoryGirl.create(:organization)

      get :index
      expect(assigns(:employer_profiles)).to eq [ep]
    end
  end 
end
