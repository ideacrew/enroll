require 'rails_helper'

RSpec.describe "insured/plan_shoppings/_plan_details.html.erb" do
  let(:carrier_profile) { instance_double("CarrierProfile", id: "carrier profile id", legal_name: "legal_name") }
  let(:plan) do
    double(plan_type: "ppo", metal_level: "bronze", is_standard_plan: true,
      nationwide: "true", total_employee_cost: 100, deductible: 500,
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
      hbx_enrollment_members: hbx_enrollment_members,
      plan: plan
    )
  end
  before :each do
    allow(Caches::MongoidCache).to receive(:lookup).with(CarrierProfile, anything).and_return(carrier_profile)
    assign(:plan_hsa_status, plan_hsa_status)
    assign(:hbx_enrollment, hbx_enrollment)
    assign(:enrolled_hbx_enrollment_plan_ids, [plan.id])
    assign(:carrier_names_map, {})
    render "insured/plan_shoppings/plan_details", plan: plan
  end

  it "should display the main menu" do
    expect(rendered).not_to have_selector('a', text: /Waive/)
  end

  it "should display plan details" do
    expect(rendered).to match(/#{plan.name}/)
    expect(rendered).to match(/#{plan.carrier_profile}/)
    expect(rendered).to match(/#{plan.active_year}/)
    expect(rendered).to match(/#{plan.deductible}/)
    expect(rendered).to match(/#{plan.is_standard_plan}/)
    expect(rendered).to match(/#{plan.nationwide}/)
    expect(rendered).to match(/#{plan.total_employee_cost}/)
    expect(rendered).to match(/#{plan.plan_type}/)
    expect(rendered).to match(/#{plan.metal_level}/)
    expect(rendered).to match(/#{plan.hios_id}/)
  end

  it "should match css selector for standard plan" do
    expect(rendered).to have_css("i.fa-bookmark", text: /standard plan/i)
    expect(rendered).to have_css("h5.bg-title", text: /your current #{plan.active_year} plan/i)
  end
end
