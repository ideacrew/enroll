FactoryGirl.define do
  factory :employer_census_family, :class => 'EmployerCensus::EmployeeFamily' do

    # employer { FactoryGirl.create :employer }
    census_employee { FactoryGirl.build :employer_census_employee }
    terminated false

    factory :with_employer do
      before :create do |employer_census_family|
        build :employer, employer_census_family: employer_census_family
      end
    end

    factory :with_dependents do
      after :create do |employer_census_family|
        create_list :employer_census_dependent, 3, employer_census_family: employer_census_family
      end
    end

  end
end
