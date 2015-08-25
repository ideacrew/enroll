require 'rails_helper'

RSpec.describe "insured/families/_enrollment.html.erb" do
  let(:plan) {FactoryGirl.build(:plan)}
  let(:hbx_enrollment) {double(plan: plan, id: "12345", total_premium: 200, covered_members_first_names: ["name"], can_complete_shopping?: false)}


  before :each do
    render partial: "insured/families/enrollment", collection: [hbx_enrollment], as: :hbx_enrollment
  end

  it "should display the title" do
    expect(rendered).to match /2015 Health Coverage/
    expect(rendered).to match /DCHL/
  end

  it "should display the link of view detail" do
    expect(rendered).to have_selector("a[href='/products/plans/summary?hbx_enrollment_id=#{hbx_enrollment.id}&standard_component_id=#{plan.hios_id}']", text: "VIEW DETAILS")
  end

end
