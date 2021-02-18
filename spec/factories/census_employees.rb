FactoryBot.define do
  factory :census_employee do
    first_name { "Eddie" }
    sequence(:last_name) {|n| "Vedder#{n}" }
    dob { "1964-10-23".to_date }
    gender { "male" }
    expected_selection { "enroll" }
    employee_relationship { "self" }
    hired_on { "2015-04-01".to_date }
    sequence(:ssn) { |n| 222222220 + n }
    is_business_owner  { false }
    association :address, strategy: :build
    association :email, strategy: :build
    association :employer_profile, strategy: :create
    # association :benefit_sponsorship, :with_organization_cca_profile, factory: :benefit_sponsors_benefit_sponsorship

    before(:create) do |instance|
      FactoryBot.create(:application_event_kind,:out_of_pocket_notice)
      instance.employer_profile = instance.benefit_sponsorship.profile if instance.benefit_sponsorship
    end

    transient do
      benefit_group { build(:benefit_group) }
      renewal_benefit_group { build(:benefit_group) }
      create_with_spouse { false }
    end

    after(:create) do |census_employee, evaluator|
      census_employee.created_at = TimeKeeper.date_of_record
      if evaluator.create_with_spouse
        census_employee.census_dependents.create(employee_relationship: 'spouse')
      end
    end

    trait :old_case do
      benefit_sponsorship_id { nil }
      benefit_sponsors_employer_profile_id { nil }
    end

    trait :owner do
      is_business_owner  { true }
    end

    trait :with_spouse do

    end

    trait :blank_email do
      email { nil }
    end
    trait :termination_details do
      # aasm_state "employment_terminated"
      employment_terminated_on {TimeKeeper.date_of_record.last_month}
      coverage_terminated_on {TimeKeeper.date_of_record.last_month.end_of_month}
    end

    trait :with_enrolled_census_employee do
      aasm_state { :eligible }
    end

    trait :general_agency do
      transient do
        general_agency_traits { [] }
        general_agency_attributes { {} }
      end

      before :create do |organization, evaluator|
        organization.office_locations.push FactoryBot.build :office_location, :primary
      end

      after :create do |organization, evaluator|
        FactoryBot.create :general_agency_profile, *Array.wrap(evaluator.general_agency_traits) + [:with_staff], evaluator.general_agency_attributes.merge(organization: organization)
      end
    end

    trait :with_active_assignment do
      after(:build) do |census_employee, evaluator|
        build(:benefit_group_assignment, benefit_group: evaluator.benefit_group, census_employee: census_employee)
      end
    end

    factory :census_employee_with_active_assignment do
      after(:create) do |census_employee, evaluator|
        create(:benefit_group_assignment, benefit_group: evaluator.benefit_group, census_employee: census_employee)
      end
    end

    factory :census_employee_with_active_and_renewal_assignment do
      after(:create) do |census_employee, evaluator|
        create(:benefit_group_assignment, benefit_group: evaluator.benefit_group, census_employee: census_employee)
        create(:benefit_group_assignment, benefit_group: evaluator.renewal_benefit_group, census_employee: census_employee)
      end
    end
  end
end
