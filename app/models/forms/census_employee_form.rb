module Forms
  class CensusEmployeeForm
    include ActiveModel::Model
    include ActiveModel::Validations

    attr_accessor :benefit_group_id
    validates_presence_of :benefit_group_id, :allow_blank => nil

    def initialize(params={})
      @params = params
    end

    def find_and_assign_attributes
      find_census_employee
      extract_benefit_group_id
      assign_benefit_group_assignments
      @census_employee
    end

    def build_and_assign_attributes
      initialize_census_employee
      find_employer_profile
      assign_census_employee_attributes
      assign_benefit_group_assignments
      assign_census_employee_to_employer_profile
      @census_employee
    end

    def assign_census_employee_attributes
      @census_employee.attributes = @params["census_employee"]
    end

    def assign_benefit_group_assignments
      extract_benefit_group_id
      find_and_assign_benefit_group
    end

    def assign_census_employee_to_employer_profile
      @census_employee.employer_profile = @employer_profile
    end

    def find_and_assign_benefit_group
      benefit_group = BenefitGroup.find(BSON::ObjectId.from_string(@benefit_group_id))
      new_benefit_group_assignment = BenefitGroupAssignment.new_from_group_and_census_employee(benefit_group, @census_employee)
      if @params["action"] == "create"
        @census_employee.benefit_group_assignments = new_benefit_group_assignment.to_a
      else
        if @census_employee.active_benefit_group_assignment.try(:benefit_group_id) != new_benefit_group_assignment.benefit_group_id
          @census_employee.add_benefit_group_assignment(new_benefit_group_assignment)
        end
      end
    end

    def extract_benefit_group_id
      @benefit_group_id = @params["census_employee"]["benefit_group_assignments_attributes"]["0"]["benefit_group_id"]
    end

    def find_employer_profile
      @employer_profile = EmployerProfile.find(@params["employer_profile_id"])
    end

    def find_census_employee
      @census_employee = CensusEmployee.find(@params["id"])
    end

    def initialize_census_employee
      @census_employee = CensusEmployee.new
    end

    def build_census_employee_related_params
      @census_employee.build_address
      @census_employee.census_dependents.build
      @census_employee.benefit_group_assignments.build
      @census_employee
    end

    def build_census_employee_params
      initialize_census_employee
      build_census_employee_related_params
    end
  end
end