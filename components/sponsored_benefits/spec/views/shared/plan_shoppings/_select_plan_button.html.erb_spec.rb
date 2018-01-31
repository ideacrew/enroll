require 'rails_helper'

RSpec.describe "shared/plan_shoppings/_select_plan_button.html.erb" do

  let(:person){ instance_double("Person") }
  let(:hbx_enrollment){ instance_double("HbxEnrollment")}
  let(:plan_1){ instance_double("Plan1", id: "test")}
  let(:plan_2){ instance_double("Plan2", id: "test")}
  let(:family){ instance_double("Family") }

  before :each do
    allow(person).to receive(:primary_family).and_return(family)
    allow(hbx_enrollment).to receive(:plan).and_return(plan_1)
    allow(family).to receive(:enrolled_hbx_enrollments).and_return([hbx_enrollment])
    assign :hbx_enrollment, hbx_enrollment
    assign :change_plan, "change_plan"
    assign :market_kind, "individual"
    assign :coverage_kind, "health"
    assign :enrollment_kind, ""
    assign :person, person
  end

  it "should show your current plan on plan comparison page" do
    render partial: "shared/plan_shoppings/select_plan_button", locals: {plan: plan_1}
    expect(rendered).to match(/YOUR CURRENT PLAN/m)
  end

  it "should match dependent count" do
    allow(plan_2).to receive(:id).and_return("test1")
    render partial: "shared/plan_shoppings/select_plan_button", locals: {plan: plan_2}
    expect(rendered).to have_css("a.interaction-click-control-select-plan")
    expect(rendered).to match(/Select Plan/)
  end

end