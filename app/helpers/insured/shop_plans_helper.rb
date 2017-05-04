module Insured::ShopPlansHelper
  def redirect_to_plans
    (@person.active_employee_roles.blank? && @person.consumer_role.present? && !is_under_open_enrollment? && !@employee_role.try(:is_under_open_enrollment?)) || !@person.active_employee_roles.blank?
  end

  def shop_plans_action
    action_path = find_sep_insured_families_path
    if @person.active_employee_roles.blank?
      action_path = find_sep_insured_families_path
    else
      if is_under_open_enrollment? || @employee_role.try(:is_eligible_to_enroll_without_qle?) || @person.consumer_role.present? || @person.resident_role.present?
        action_path = new_insured_group_selection_path
      end
    end
    action_path
  end
end
