FactoryGirl.define do
  factory :employer_census_family, :class => 'EmployerCensus::EmployeeFamily' do

    # employer { FactoryGirl.create :employer }
    employer_profile
    association :census_employee, factory: :employer_census_employee, strategy: :build
    terminated false

    factory :with_employer do
      before :create do |employer_census_family|
        association :employer_profile, employer_census_family: employer_census_family, strategy: :build
      end
    end

    factory :with_dependents do
      after :create do |employer_census_family|
        create_list :employer_census_dependent, 3, employer_census_family: employer_census_family
      end
    end

  end
end
