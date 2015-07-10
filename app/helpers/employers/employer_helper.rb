module Employers::EmployerHelper
  def address_kind
    @family.try(:census_employee).try(:address).try(:kind) || 'home'
  end

  def enrollment_state(census_employee=nil)
    return "" if census_employee.blank?

    enrollment_state = census_employee.active_benefit_group_assignment.try(:aasm_state)
    if enrollment_state.present? and enrollment_state != "initialized"
      enrollment_state.humanize
    else
      ""
    end
  end
end
