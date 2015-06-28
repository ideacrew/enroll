FactoryGirl.define do
  factory :broker_role do
    person { FactoryGirl.create(:person) }
    sequence(:npn) {|n| "2002345#{n}" }
    provider_kind {"broker"}

    trait :with_invalid_provider_kind do
      provider_kind ' '
    end
  end
end
