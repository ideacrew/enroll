require "rails_helper"

RSpec.describe "employers/employer_profiles/my_account/_employees_by_status.html.erb" do
  let(:employer_profile) { FactoryGirl.create(:employer_profile) }
  let(:census_employee1) { FactoryGirl.create(:census_employee, employer_profile: employer_profile) }
  let(:census_employee2) { FactoryGirl.create(:census_employee, employer_profile: employer_profile) }
  let(:census_employee3) { FactoryGirl.create(:census_employee, employer_profile: employer_profile) }
  let(:user) { FactoryGirl.create(:user) }

  before :each do
    allow(census_employee1).to receive(:active_benefit_group_assignment).and_return(double(aasm_state: "initialized"))
    allow(census_employee2).to receive(:active_benefit_group_assignment).and_return(double(aasm_state: "coverage_selected"))
    allow(census_employee3).to receive(:active_benefit_group_assignment).and_return(double(aasm_state: "coverage_terminated"))
    assign(:census_employees, [census_employee1, census_employee2, census_employee3])
    assign(:employer_profile, employer_profile)
    assign(:page_alphabets, ['a', 'b', 'c'])

    sign_in user
    stub_template "shared/alph_paginate" => ''
    render "employers/employer_profiles/my_account/employees_by_status", :status => "all"
  end

  it "should displays enrollment state" do
    expect(rendered).to match(/Enrollment Status/)
    expect(rendered).to match(/Coverage selected/)
    expect(rendered).to match(/Coverage terminated/)
  end
end
