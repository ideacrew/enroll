FactoryGirl.define do
  factory :consumer_role do
    sequence(:ssn) { |n| "75634863" + "#{n}" }
    dob "01/01/1980"
    gender 'male'
    is_state_resident 'yes'
    citizen_status 'citizen'
    is_incarcerated 'yes'
    is_applicant 'yes'

  end
end
