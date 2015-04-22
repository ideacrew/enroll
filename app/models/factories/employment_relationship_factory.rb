module Factories
  class EmploymentRelationshipFactory
    def initialize

    end

    def build(employee_candidate, employee_family)
      benefit_group = employee_family.benefit_group
      hired_on = employee_family.census_employee.hired_on
      employer = employee_family.employer_profile
      ::Forms::EmploymentRelationship.new({
        :employer_name => employer.dba,
        :first_name => employee_candidate.first_name,
        :last_name => employee_candidate.last_name,
        :middle_name => employee_candidate.middle_name,
        :name_pfx => employee_candidate.name_pfx,
        :name_sfx => employee_candidate.name_sfx,
        :gender => employee_candidate.gender,
        :employee_family_id => employee_family.id,
        :hired_on => hired_on,
        :eligible_for_coverage_on => benefit_group.effective_on_for(hired_on)
      })
    end

    def self.build(employee_candidate, employee_families)
      factory = self.new
      employee_families.map { |e_family| factory.build(employee_candidate, e_family) }
    end
  end
end
