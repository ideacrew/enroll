FactoryGirl.define do
  factory :broker_role do
    person { FactoryGirl.create(:person, :with_work_phone, :with_work_email) }
    sequence(:npn) {|n| "2002345#{n}" }
    provider_kind {"broker"}

    trait :with_invalid_provider_kind do
      provider_kind ' '
    end
  end
end
