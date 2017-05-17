module Exchanges::HbxProfilesHelper

  def employee_eligibility_status(enrollment)
    if enrollment.is_shop?
      if enrollment.benefit_group_assignment.present?
        if enrollment.benefit_group_assignment.census_employee.can_be_reinstated?
          enrollment.benefit_group_assignment.census_employee.aasm_state.camelcase
        end
      end
    end
  end
end