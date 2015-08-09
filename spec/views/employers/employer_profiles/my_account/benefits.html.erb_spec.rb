require "rails_helper"

RSpec.describe "employers/employer_profiles/my_account/_benefits.html.erb" do
  let(:employer_profile) { FactoryGirl.create(:employer_profile) }
  let(:plan_year) { FactoryGirl.create(:plan_year) }
  let(:benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year) }

  before :each do
    allow(plan_year).to receive(:benefit_groups).and_return([benefit_group])
    assign(:plan_years, [plan_year])
    assign(:employer_profile, employer_profile)
  end

  it "should display contribution pct by integer" do
    render "employers/employer_profiles/my_account/benefits"
    expect(rendered).to match(/Plan Year/)
    plan_year.benefit_groups.first.relationship_benefits.map(&:premium_pct).each do |pct|
      expect(rendered).to have_selector("td", text: "#{pct.to_i}%")
    end
  end
end
