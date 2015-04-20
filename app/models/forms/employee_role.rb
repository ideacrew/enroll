module Forms
  class EmployeeRole < SimpleDelegator
    attr_accessor :employee_role_id
    attr_accessor :census_employee_id
    attr_accessor :census_family_id
    attr_accessor :employer_profile_id

    def initialize(person)
      super(person)
    end

    def self.model_name
      Person.model_name
    end
  end
end
