FactoryGirl.define do
  factory :census_employee do
    first_name "Eddie"
    sequence(:last_name) {|n| "Vedder\##{n}" }
    dob "10/23/1964"
    gender "male"
    employee_relationship "self"
    hired_on "04/01/2015"
    sequence(:ssn, 222222220)
    is_owner  false
    association :address, strategy: :build
    association :email, strategy: :build

    trait :is_owner do
      is_owner  true
    end
  end

end
