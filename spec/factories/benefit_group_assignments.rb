FactoryBot.define do
  factory :benefit_group_assignment do
    benefit_group
    start_on { benefit_group.plan_year.start_on }
    is_active { true }

    trait :coverage_selected do
      hbx_enrollment
      aasm_state { "coverage_selected" }
    end
  end
end
