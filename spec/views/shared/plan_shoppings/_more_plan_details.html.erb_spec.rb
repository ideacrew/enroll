require 'rails_helper'

RSpec.describe "shared/plan_shoppings/_more_plan_details.html.erb" do

  let(:person){
    instance_double(
      "Person",
      full_name: "my full name"
      )
  }

  let(:hbx_enrollment){
    instance_double(
      "HbxEnrollment"
      )
  }

  let(:plan){
    instance_double(
      "Plan"
      )
  }

  let(:plan_count){
    [plan, plan, plan, plan]
  }

  before :each do
    allow(hbx_enrollment).to receive(:humanized_dependent_summary).and_return(2)
    allow(person).to receive(:has_consumer_role?).and_return(false)

    assign :hbx_enrollment, hbx_enrollment
    assign :plans, plan_count
    assign :person, person
    render partial: "shared/plan_shoppings/more_plan_details"
  end

  it "should match person full name" do
    expect(rendered).to match /Coverage For.*#{person.full_name}.*/m
  end

  it "should match dependent count" do
    expect(rendered).to match /.*#{hbx_enrollment.humanized_dependent_summary} dependent*/m
  end

  it "should match plan count" do
    expect(rendered).to match /Plans.*#{plan_count}.*/
  end

end
