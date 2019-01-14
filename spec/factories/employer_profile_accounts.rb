FactoryBot.define do
  factory :employer_profile_account do
    next_premium_due_on TimeKeeper.date_of_record.end_of_month + 1.day
    next_premium_amount 5489.97
  end

end
