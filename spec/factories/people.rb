FactoryGirl.define do
  factory :person do
    # name_pfx 'Mr'
    first_name 'John'
    # middle_name 'X'
    sequence(:last_name) {|n| "Smith\##{n}" }
    # name_sfx 'Jr'
    dob "04/04/1972"
    is_active true

    after(:create) do |p, evaluator|
      create_list(:address, 2, person: p)
      create_list(:phone, 2, person: p)
      create_list(:email, 2, person: p)
    end

    trait :without_first_name do
      first_name ' '
    end

    trait :without_last_name do
      last_name ' '
    end

    factory :invalid_person, traits: [:without_first_name, :without_last_name]

    trait :male do
      gender "male"
    end

    trait :female do
      gender "female"
    end

    factory :male do
      gender "male"
    end

    factory :female do
      gender "female"
    end
  end

end
