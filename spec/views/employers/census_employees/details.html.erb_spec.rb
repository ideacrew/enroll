require "rails_helper"

RSpec.describe "employers/census_employees/_details.html.erb" do
  let(:employer_profile) { FactoryGirl.create(:employer_profile) }
  let(:census_employee) { FactoryGirl.create(:census_employee, employer_profile: employer_profile) }
  let(:benefit_group_assignment) { double(benefit_group: benefit_group) }
  let(:benefit_group) {double(title: "plan name")}

  before(:each) do
    assign(:census_employee, census_employee)
    allow(census_employee).to receive(:active_benefit_group_assignment).and_return(benefit_group_assignment)
    allow(benefit_group_assignment).to receive(:coverage_waived?).and_return(true)

    render template: "employers/census_employees/_details.html.erb"
  end

  it "should show the plan" do
    expect(rendered).to match /Plan/
    expect(rendered).to have_selector('p', text: 'plan name')
  end

  it "should show waiver" do
    expect(rendered).to match /Waiver/
  end
end
