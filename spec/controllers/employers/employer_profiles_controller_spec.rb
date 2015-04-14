require 'rails_helper'

RSpec.describe Employers::EmployerProfilesController, :type => :controller do
  describe "create employer" do
    login_user 
    include_context "BradyWork"
    let(:organization) { mikes_organization }
    let(:employer_profile) { mikes_employer }
    let(:plan_year) { mikes_plan_year }
    let(:benefit_group) { mikes_benefit_group }

    it "create successful" do
      benefit_group_params = benefit_group.attributes.to_hash.delete_if {|k, v| k=="_id"}
      plan_year_params = plan_year.attributes.to_hash.delete_if {|k, v| k=="_id"}
      plan_year_params[:benefit_groups_attributes] = {"0" => benefit_group_params}
      employer_profile_params = employer_profile.attributes.to_hash.delete_if {|k, v| k=="_id"}
      employer_profile_params[:plan_years_attributes] = {"0" => plan_year_params}
      organization_params = organization.attributes.to_hash.delete_if {|k, v| k=="_id"}
      organization_params[:employer_profile_attributes] = employer_profile_params

      organization.destroy
      org_count = Organization.count
      post :create, organization: organization_params
      expect(Organization.count).to eq (org_count + 1)
      expect(controller.flash.now[:notice]).to eq "Employer successfully created." 
    end

    it "create failure" do
    end
  end
end
