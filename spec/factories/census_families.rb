FactoryGirl.define do
  factory :census_family do
    employer_profile
    association :census_employee, factory: :census_employee, strategy: :build
    # benefit_group_assignments { [FactoryGirl.build(:employer_census_benefit_group_assignment)] }
    is_terminated false

    trait :is_terminated do
      is_terminated true
    end
  end

end
