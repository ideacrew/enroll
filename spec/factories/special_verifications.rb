FactoryBot.define do
  factory :special_verification do
    due_date {TimeKeeper.date_of_record + 96.days}
    verification_type { "Citizenship" }
    updated_by { FactoryBot.build(:user).id}
    type { "admin" }

    after(:build) do |sv, evaluator|
      p = FactoryBot.create(:person, :with_consumer_role)
      p.consumer_role.special_verifications << sv
      p.save
    end
  end
end
