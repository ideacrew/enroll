require "rails_helper"

RSpec.describe "employers/employer_profiles/my_account/_census_employees.html.erb" do
  let(:employer_profile) { FactoryGirl.create(:employer_profile) }

  before :each do
    assign(:employer_profile, employer_profile)
    assign(:avaliable_employee_names, "employee_names")
    assign(:census_employees, [])
    render "employers/employer_profiles/my_account/census_employees"
  end

  it "should display title" do
    expect(rendered).to match(/Employee Roster/)
  end

  it "should have active filter option" do
    expect(rendered).to have_selector("input[value='active']")
  end

  it "should have terminated filter option" do
    expect(rendered).to have_selector("input[value='terminated']")
  end

  it "should have all filter option" do
    expect(rendered).to have_selector("input[value='all']")
  end

  it "should not have waive filter option" do
    expect(rendered).not_to have_selector("input[value='waived']")
  end
end
