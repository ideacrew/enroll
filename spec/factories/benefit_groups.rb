FactoryGirl.define do
  factory :benefit_group do
    plan_year
    # benefit_list {  }
    effective_on_kind "date_of_hire"
    terminate_on_kind "end_of_month"
    effective_on_offset 30
    association :reference_plan, factory: :plan
    premium_pct_as_int 65
    employer_max_amt_in_cents 400_00
  end
end
