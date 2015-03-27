FactoryGirl.define do
  factory :benefit_group do
    plan_year
    benefit_list { [
      BenefitGroup::Benefit.new(:employee,                   80, 1000_00),
      BenefitGroup::Benefit.new(:spouse,                     40,  200_00),
      BenefitGroup::Benefit.new(:domestic_partner,           40,  200_00),
      BenefitGroup::Benefit.new(:child_under_26,             40,  200_00),
      BenefitGroup::Benefit.new(:disabled_child_26_and_over, 40,  200_00)
      ] }
    effective_on_kind "date_of_hire"
    terminate_on_kind "end_of_month"
    effective_on_offset 30
    association :reference_plan, factory: :plan
    premium_pct_as_int 80
    employer_max_amt_in_cents 1000_00
  end
end
