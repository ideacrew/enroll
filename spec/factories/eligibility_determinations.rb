FactoryGirl.define do
  factory :eligibility_determination do
    tax_household
    determined_on TimeKeeper.datetime_of_record
    max_aptc  225.13
    csr_percentage_as_integer 87
    premium_credit_strategy_kind "allocated_lump_sum_credit"
    e_pdc_id "3110344"
  end

end
