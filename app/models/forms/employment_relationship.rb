module Forms
  class EmploymentRelationship
    include ActiveModel::Model

    attr_accessor :employer_name, :hired_on, :eligible_for_coverage_on, :census_employee_id, :gender , :is_cobra_dependent

    include ::Forms::PeopleNames

    def census_employee
      ::CensusEmployee.find(census_employee_id)
    end
    

  end
end
