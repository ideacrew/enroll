FactoryGirl.define do
  factory :benefit_group_assignment do
    benefit_group
    hbx_enrollment
    start_on { benefit_group.plan_year.start_on }
    aasm_state "coverage_selected"
    is_active true
  end
end
