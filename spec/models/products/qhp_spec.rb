require 'rails_helper'

describe Products::Qhp, :type => :model do
  it { should validate_presence_of :issuer_id }
  it { should validate_presence_of :state_postal_code }
  it { should validate_presence_of :standard_component_id }
  it { should validate_presence_of :plan_marketing_name }
  it { should validate_presence_of :hios_product_id }
  it { should validate_presence_of :network_id }
  it { should validate_presence_of :service_area_id }
  it { should validate_presence_of :is_new_plan }
  it { should validate_presence_of :plan_type }
  it { should validate_presence_of :metal_level }
  it { should validate_presence_of :qhp_or_non_qhp }
  it { should validate_presence_of :emp_contribution_amount_for_hsa_or_hra }
  it { should validate_presence_of :child_only_offering }
  it { should validate_presence_of :plan_effective_date }
  it { should validate_presence_of :out_of_country_coverage }
  it { should validate_presence_of :out_of_service_area_coverage }
  it { should validate_presence_of :national_network }
  # FIXME: Re-enable once we have compliant SERFF templates from Kaiser
  #  it { should validate_presence_of :summary_benefit_and_coverage_url }

  let(:plan){ FactoryBot.create(:plan) }
  let(:qhp) { FactoryBot.build(:products_qhp) }

  it "should set plan_id" do
    qhp.plan = plan
    expect(qhp.plan_id).to eq plan.id
  end

  it "should get the plan" do
    qhp.plan = plan
    expect(qhp.plan).to be_an_instance_of Plan
    expect(qhp.plan.id).to eq qhp.plan_id
  end
end
