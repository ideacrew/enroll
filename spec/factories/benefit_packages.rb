FactoryGirl.define do
  factory :benefit_package do
    association :benefit_coverage_period
    elected_premium_credit_strategy { "unassisted" }
    benefit_begin_after_event_offsets { [30, 60, 90] }
    benefit_effective_dates { ["first_of_month"] }
    end 
end
