# frozen_string_literal: true

#insured/plan_shoppings/thankyou?change_plan=&coverage_kind=health&enrollment_kind=&market_kind=shop&plan_id
class EmployeeConfirmYourPlanSelection

  def self.previous_link
    '.interaction-click-control-previous'
  end

  def self.save_and_exit_link
    '.interaction-click-control-save---exit'
  end

  def self.waive_coverage
    '.interaction-click-control-waive-coverage'
  end

  def self.coverage_effective_date
    '.coverage_effective_date'
  end

  def self.confirm_btn
    '#btn-continue'
  end
end