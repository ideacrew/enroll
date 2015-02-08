FactoryGirl.define do
  factory :employer_census_employee_family, :class => 'EmployerCensus::Family' do

    before(:create) do |f, evaluator|
      create(:employee, employee: f)
    end

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
