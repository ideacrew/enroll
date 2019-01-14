FactoryBot.define do
  factory :census_dependent do
    first_name "Mary"
    last_name "Doe"
    dob "01/12/1980"
    gender "female"
    employee_relationship "spouse"
    sequence :ssn, "333333333"
  end

end
