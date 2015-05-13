FactoryGirl.define do
  factory :employer_census_benefit_group_assignment, :class => 'EmployerCensus::BenefitGroupAssignment' do
    benefit_group 
    start_on "2015-04-28".to_date
    end_on "2015-12-31".to_date
  end

end
