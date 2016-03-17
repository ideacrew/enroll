FactoryGirl.define do
  factory :benefit_sponsorship do
    service_markets %W(individual shop)
    benefit_coverage_periods { [FactoryGirl.build(:benefit_coverage_period)] }

    trait :open_enrollment_coverage_period do
       benefit_coverage_periods { [FactoryGirl.build(:benefit_coverage_period, :open_enrollment_coverage_period)] }
    end

    trait :no_open_enrollment_coverage_period do
       benefit_coverage_periods { [FactoryGirl.build(:benefit_coverage_period, :no_open_enrollment_coverage_period)] }
    end
  end
end
