FactoryBot.define do
  factory :person do
    # name_pfx 'Mr'
    first_name { 'John' }
    # middle_name 'X'
    sequence(:last_name) {|n| "Smith#{n}" }
    # name_sfx 'Jr'
    dob { "1972-04-04".to_date }
    is_incarcerated { false }
    is_active { true }
    gender { "male" }

    trait :with_broker_role do
      after(:create) do |p, evaluator|
        create_list(:broker_role, 1, person: p)
      end
    end

    trait :with_family do
      after :create do |person|
        family = FactoryBot.create :family, :with_primary_family_member, person: person
      end
    end

    trait :with_work_phone do
      phones { [FactoryBot.build(:phone, kind: "work") ] }
    end

    trait :with_work_email do
      emails { [FactoryBot.build(:email, kind: "work") ] }
    end

    trait :with_employee_role do
      after(:create) do |p, _evaluator|
        create_list(:benefit_sponsors_employee_role, 1, person: p)
      end
    end
  end
end
