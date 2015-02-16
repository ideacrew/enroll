FactoryGirl.define do
  factory :employee do
    association :person, ssn: '123456789', dob: "1/1/1965", gender: "female", first_name: "Sarah", last_name: "Employee"
    association :employer
    hired_on {20.months.ago}

  end

end
