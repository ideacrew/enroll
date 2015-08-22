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

  def render_plan_offerings(benefit_group)
    plan_offerings = "1 Plan Only"
    if benefit_group.plan_option_kind != "single_plan"
      reference_plan = benefit_group.reference_plan
      if benefit_group.plan_option_kind == "single_carrier"
        plan_offerings = "All #{reference_plan.carrier_profile.legal_name} Plans (#{benefit_group.elected_plan_ids.count})"
      else
        plan_offerings = "#{reference_plan.metal_level.titleize} Plans (#{benefit_group.elected_plan_ids.count})"
      end
    end
    plan_offerings
  end
end
