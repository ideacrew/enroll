require 'rails_helper'

RSpec.describe "events/hbx_emrollment/policy.haml.erb" do

  let(:plan) { FactoryGirl.create(:plan) }
  let(:employee_role) { FactoryGirl.create(:employee_role) }
  let(:hbx_enrollment) {  HbxEnrollment.new(plan:plan, employee_role: employee_role) }

  it "generates a policy cv with policy, enrollees and plan elements" do
    render :template=>"events/hbx_enrollment/policy", :locals=>{hbx_enrollment: hbx_enrollment}
    expect(rendered).to include("</policy>")
    expect(rendered).to include("<enrollees>")
    expect(rendered).to include("<plan>")
    expect(rendered).to include("<premium_total_amount>")
    expect(rendered).to include("<total_responsible_amount>")
  end
end
