FactoryGirl.define do
  factory :employer_census_benefit_group_assignment, :class => 'EmployerCensus::BenefitGroupAssignment' do
    benefit_group 
    start_on Date.current
    end_on Date.current + 30
  end

end
