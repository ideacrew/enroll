FactoryBot.define do
  factory :lawful_presence_determination do
    vlp_verified_at { 2.days.ago }
    citizen_status { "citizen" }
    aasm_state { "verification_successful" }

    trait :us_citizen do
      citizen_status { 'us_citizen' }
    end
  end
end
