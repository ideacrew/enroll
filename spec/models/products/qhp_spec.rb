require 'rails_helper'

describe Products::Qhp, :type => :model do
  it { should validate_presence_of :issuer_id }
  it { should validate_presence_of :state_postal_code }
  it { should validate_presence_of :standard_component_id }
  it { should validate_presence_of :plan_marketing_name }
  it { should validate_presence_of :hios_product_id }
  it { should validate_presence_of :network_id }
  it { should validate_presence_of :service_area_id }
  it { should validate_presence_of :formulary_id }
  it { should validate_presence_of :is_new_plan }
  it { should validate_presence_of :plan_type }
  it { should validate_presence_of :metal_level }
  it { should validate_presence_of :unique_plan_design }
  it { should validate_presence_of :qhp_or_non_qhp }
  it { should validate_presence_of :insurance_plan_pregnancy_notice_req_ind }
  it { should validate_presence_of :is_specialist_referral_required }
  it { should validate_presence_of :hsa_eligibility }
  it { should validate_presence_of :emp_contribution_amount_for_hsa_or_hra }
  it { should validate_presence_of :child_only_offering }
  it { should validate_presence_of :is_wellness_program_offered }
  it { should validate_presence_of :plan_effective_date }
  it { should validate_presence_of :out_of_country_coverage }
  it { should validate_presence_of :out_of_service_area_coverage }
  it { should validate_presence_of :national_network }
  it { should validate_presence_of :summary_benefit_and_coverage_url }

end
