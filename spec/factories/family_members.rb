FactoryGirl.define do
  factory :family_member do
    family
    person
    is_primary_applicant false
    is_coverage_applicant true

    trait :primary do
      is_primary_applicant true
    end
  end
end
