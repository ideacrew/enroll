require 'rails_helper'

describe "shared/census_dependent_fields.html.erb" do
  let(:hbx_enrollment) { double(waiver_reason: "this is reason") }
  let(:benefit_group_assignment) { double(hbx_enrollment: hbx_enrollment) }

  before :each do
    render "shared/waive", :benefit_group_assignment =>benefit_group_assignment 
  end

  it "should have enrollment status" do
    expect(rendered).to match /Coverage Waived/
  end

  it "should show waiver reason" do
    expect(rendered).to match /Waiver Reason: this is reason/
  end

  it "should show waiver date" do
    expect(rendered).to match /Waiver on:/
  end
end
