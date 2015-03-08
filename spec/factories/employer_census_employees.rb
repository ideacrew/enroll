FactoryGirl.define do
  factory :employer_census_employee, :class => 'EmployerCensus::Employee' do
    first_name "John"
    last_name "Doe"
    dob "01/12/1980"
    gender "male"
    employee_relationship "self"
    hired_on "01/01/2015"
    sequence(:ssn, 111111111)
    association :address, strategy: :build
    association :email, strategy: :build
  end

end
