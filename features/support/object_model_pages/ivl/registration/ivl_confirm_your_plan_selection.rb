# frozen_string_literal: true

#insured/plan_shoppings/5ff897c796a4a17b7bf8930b/thankyou?change_plan=&coverage_kind=health&enrollment_kind=&market_kind=individual&plan_id
class IvlConfirmYourPlanSelection

  def self.i_agree_checkbox
    '#terms_check_thank_you'
  end

  def self.first_name
    'first_name_thank_you'
  end

  def self.last_name
    'last_name_thank_you'
  end

  def self.confirm_btn
    '#btn-continue'
  end

  def self.dup_enrollment_warning_1
    'The following person currently has coverage on'
  end

  def self.dup_enrollment_warning_2
    'Enrolling in a new plan will remove existing coverage for these persons'
  end
end