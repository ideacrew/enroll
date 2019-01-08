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

<<<<<<< HEAD
    trait :with_ssn do
      sequence(:ssn) { |n| 222222220 + n }
=======
    trait :with_general_agency_staff_role do
      after(:create) do |p, evaluator|
        create_list(:general_agency_staff_role, 1, person: p)
      end
>>>>>>> a9f7d97290... added specs
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
  end
end
