FactoryGirl.define do
  factory :employer_census_employee_family, :class => 'EmployerCensus::EmployeeFamily' do

    # employer { FactoryGirl.create :employer }
    employee { FactoryGirl.build :employer_census_employee }
    dependents { FactoryGirl.build(:employer_census_dependent).to_a }
    terminated false

    factory :employer_census_employee_family_with_dependents do
      transient do
        dependents_count 3
      end

      after(:create) do |employer_census_employee_family, evaluator|
        create_list(:dependent, evaluator.dependents_count, dependent: broker)
      end
    end

  end
end
