FactoryGirl.define do
  factory :broker do
    first_name 'John'
    sequence(:npn) { |n| "#{n}"}
    kind 'broker'

    after(:create) do |b, evaluator|
      create_list(:address, 2, broker: b)
      create_list(:phone, 2, broker: b)
      create_list(:email, 2, broker: b)
    end

    trait :with_invalid_b_type do
      kind ' '
    end
  end
end
