FactoryGirl.define do
  factory :individual_market_transition do
    association :person

    role_type 'consumer'
    reason_code 'reason1'


    trait :resident do
      role_type 'resident'
      reason_code 'reason2'
    end
  end
end