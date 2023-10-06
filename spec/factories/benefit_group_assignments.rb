FactoryBot.define do
  factory :benefit_group_assignment do
    benefit_group
    start_on { benefit_group.benefit_application.start_on }

    trait :coverage_selected do
      hbx_enrollment
    end
  end
end
