FactoryGirl.define do
  factory :employer_census_employee, :class => 'EmployerCensus::Employee' do
    first_name "John"
    last_name "Doe"
    dob "01/12/1980"
    gender "male"
    employee_relationship "spouse"
    date_of_hire "01/01/2015"
    ssn "222222222"
  end

end
