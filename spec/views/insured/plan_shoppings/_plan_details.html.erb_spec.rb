require 'rails_helper'

RSpec.describe "insured/plan_shoppings/_plan_details.html.erb" do
  let(:carrier_profile) { instance_double("CarrierProfile", id: "carrier profile id", dba: "dba") }
  let(:plan) do
    double(plan_type: nil, metal_level: "bronze",
      nationwide: nil, total_employee_cost: 100, deductible: 500,
      name: "My Plan", id: "my id", carrier_profile: nil,
      hios_id: "hios id", carrier_profile_id: carrier_profile.id,
      active_year: TimeKeeper.date_of_record.year, total_premium: 300,
      total_employer_contribution: 200
    )
  end
  let(:plan_hsa_status) { Hash.new }
  let(:hbx_enrollment_members) do
    []
  end
  let(:hbx_enrollment) do
    instance_double(
      "HbxEnrollment", id: "hbx enrollment id",
      hbx_enrollment_members: hbx_enrollment_members
    )
  end
  before :each do
    allow(Caches::MongoidCache).to receive(:lookup).with(CarrierProfile, anything).and_return(carrier_profile)
    assign(:plan_hsa_status, plan_hsa_status)
    assign(:hbx_enrollment, hbx_enrollment)
    render "insured/plan_shoppings/plan_details", plan: plan
  end

  it "should display the main menu" do
    expect(rendered).not_to have_selector('a', text: /Waive/)
  end
end
