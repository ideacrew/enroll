FactoryGirl.define do
  factory :broker do
    npn "abx123xyz"
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
