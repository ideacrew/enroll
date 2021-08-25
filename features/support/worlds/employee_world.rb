# frozen_string_literal: true

# This world should contain useful steps for data related to the shop market
module EmployeeWorld
  def create_health_enrollment_for_employee(employee_role, benefit_package, sponsored_benefit, state)
    family = employee_role.person.primary_family
    enrollment = FactoryBot.create(:hbx_enrollment,
                                   household: family.latest_household,
                                   family: family,
                                   coverage_kind: 'health',
                                   effective_on: benefit_package.start_on,
                                   kind: "employer_sponsored",
                                   benefit_sponsorship_id: benefit_package.benefit_application.benefit_sponsorship.id,
                                   sponsored_benefit_package_id: benefit_package.id,
                                   sponsored_benefit_id: sponsored_benefit.id,
                                   employee_role_id: employee_role.id,
                                   benefit_group_assignment: employee_role.census_employee.active_benefit_group_assignment,
                                   product_id: sponsored_benefit.reference_product.id,
                                   aasm_state: state)

    enrollment.update_attributes(terminated_on: @prior_application.start_on + 4.months) if state == 'coverage_terminated'
  end
end

World(EmployeeWorld)