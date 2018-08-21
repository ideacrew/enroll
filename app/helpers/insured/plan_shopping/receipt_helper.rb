module Insured::PlanShopping::ReceiptHelper
  def show_pay_now?
    (carrier_with_payment_option? && individual? && (!has_any_previous_kaiser_enrollments? || has_break_in_coverage_enrollments?))
  end

  def carrier_with_payment_option?
    @enrollment.plan.carrier_profile.legal_name == 'Kaiser'
  end

  def individual?
    @enrollment.kind == ('individual' || 'coverall')
  end

  def has_any_previous_kaiser_enrollments?
    all_kaiser_enrollments = @enrollment.family.enrollments.select { |enr| enr.plan.carrier_profile.legal_name == 'Kaiser' && enr.effective_on.year == @enrollment.effective_on.year }
    enrollments = all_kaiser_enrollments - @enrollment.to_a
    enrollments.present? ? true : false
  end

  def has_break_in_coverage_enrollments?
    @enrollment.family.enrollments.terminated.any? { |enr| enr.plan.carrier_profile.legal_name == 'Kaiser' &&  enr.terminated_on.year == @enrollment.effective_on.year && (@enrollment.effective_on - enr.terminated_on) > 1 }
  end
end
