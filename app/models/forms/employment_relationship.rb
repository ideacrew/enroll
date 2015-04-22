module Forms
  class EmploymentRelationship
    include ActiveModel::Model

    attr_accessor :employer_name, :hired_on, :eligible_for_coverage_on, :employee_family_id, :gender

    include ::Forms::PeopleNames

    def employee_family
      ::EmployerCensus::EmployeeFamily.find(employee_family_id)
    end
  end
end
