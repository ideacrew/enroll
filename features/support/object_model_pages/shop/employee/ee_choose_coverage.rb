# frozen_string_literal: true

#insured/group_selections/new?change_plan=&employee_role_id&person_id
class EmployeeChooseCoverage

  def self.primary_checkbox
    '#family_member_ids_0'
  end

  def self.dependent_1_checkbox
    '#family_member_ids_1'
  end

  def self.shop_benefits_radio_btn
    'label[for="market_kind_shop"] span'
  end

  def self.health_radio_btn
    'label[for="coverage_kind_health"] span'
  end

  def self.dental_radio_btn
    'label[for="coverage_kind_dental"] span'
  end

  def self.shop_for_new_plan_btn
    'input[class="btn btn-primary  btn-lg no-op  interaction-click-control-shop-for-new-plan"]'
  end

  def self.keep_existing
    'input[class="btn btn-primary  btn-lg no-op  interaction-click-control-keep-existing-plan"]'
  end

  def self.back_to_my_acct_btn
    '.interaction-click-control-back-to-my-account'
  end

  def self.waive_coverage
    '.interaction-click-control-waive-coverage'
  end

  def self.continue_btn
    '.interaction-click-control-continue'
  end
end