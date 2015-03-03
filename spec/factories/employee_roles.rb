FactoryGirl.define do
  factory :employee_role do
    association :person, ssn: '123456789', dob: "1/1/1965", gender: "female", first_name: "Sarah", last_name: "Smile"
    association :employer_profile
    hired_on {20.months.ago}

  end

end
