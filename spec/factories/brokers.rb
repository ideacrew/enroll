FactoryGirl.define do
  factory :broker do
    person { FactoryGirl.build(:person) }
    sequence(:npn) {|n| "abcxyz\##{n}" }
    provider_kind {"broker"}

    trait :with_invalid_provider_kind do
      provider_kind ' '
    end
  end
end
