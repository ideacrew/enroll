require "rails_helper"

RSpec.describe "employers/employer_profiles/my_account/_enrollment_progress_bar.html.erb" do
  let!(:employer_profile) { FactoryGirl.create(:employer_profile)}
  let(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: Date.new(2015,1,1)) }
  let(:benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year) }


  context "when plan year is 1/1 plan year" do

    it "should not see enrollment target" do
      assign(:current_plan_year, plan_year)
      render "employers/employer_profiles/my_account/enrollment_progress_bar", :current_plan_year => plan_year
      expect(rendered).to have_selector("divider-progress", count: 0)
    end

  end
end
