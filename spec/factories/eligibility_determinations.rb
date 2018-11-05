FactoryGirl.define do
  factory :eligibility_determination do
    tax_household
    determined_on Time.now
    determined_at Time.now
    max_aptc  225.13
    csr_percent_as_integer 87
    csr_eligibility_kind "csr_94"
    premium_credit_strategy_kind "allocated_lump_sum_credit"
    e_pdc_id "3110344"
  end
end
