FactoryBot.define do
  factory :curam_user do
    first_name { "Ivan" }
    last_name { "Lisyk" }
    email { "Test@example.com" }
    sequence(:ssn) {|n| "7"+SecureRandom.random_number.to_s[2..8][0..-((Math.log(n+1,10))+1)]+"#{n+1}"}
    dob { Date.new(1980, 1, 1) }
  end
end
