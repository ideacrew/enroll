FactoryBot.define do
  factory :premium_payment do
    paid_on  TimeKeeper.date_of_record.beginning_of_month - 1.day
    amount  7215.12
    method_kind  "ach"
    sequence(:reference_id)     { |n| "zzz777\##{n}" }
    sequence(:document_uri)     { |n| "http://example.com/abc\##{n}" }
  end

end
