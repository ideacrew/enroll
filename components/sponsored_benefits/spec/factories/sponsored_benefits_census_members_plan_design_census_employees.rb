FactoryGirl.define do
  factory :sponsored_benefits_census_members_plan_design_census_employee, class: 'SponsoredBenefits::CensusMembers::PlanDesignCensusEmployee' do

    first_name "Eddie"
    sequence(:last_name) {|n| "Vedder#{n}" }
    dob "1964-10-23".to_date
    gender "male"
    expected_selection "enroll"
    employee_relationship "self"
    hired_on "2015-04-01".to_date
    sequence(:ssn) { |n| 222222220 + n }
    is_business_owner  false
    association :address, strategy: :build
    association :email, strategy: :build
    association :sponsored_benefits_benefit_sponsorships_plan_design_employer_profile, strategy: :build

    transient do
      create_with_spouse false
    end

    after(:create) do |census_employee, evaluator|
      census_employee.created_at = TimeKeeper.date_of_record
      if evaluator.create_with_spouse
        census_employee.census_dependents.create(employee_relationship: 'spouse')
      end
    end

    trait :owner do
      is_business_owner  true
    end

    trait :with_spouse do

    end

    trait :blank_email do
      email nil
    end
  end
end
