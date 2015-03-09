FactoryGirl.define do
  factory :employer_census_dependent, :class => 'EmployerCensus::Dependent' do
    first_name "Mary"
    last_name "Doe"
    dob "01/12/1980"
    gender "female"
    employee_relationship "spouse"
    sequence :ssn, "333333333"

  end

end
