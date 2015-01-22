FactoryGirl.define do
  factory :consumer do
    ssn '1111111111'
    dob "01/01/1980"
    gender 'male'
    is_state_resident 'yes'
    citizen_status 'citizen'

  end
end
