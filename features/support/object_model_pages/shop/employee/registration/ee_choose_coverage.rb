# frozen_string_literal: true

#insured/group_selections/new?change_plan=&employee_role_id&person_id
class EmployeeChooseCoverage

  def self.group_selection_page
    '#group-selection-form'
  end

  def self.primary_checkbox
    '#family_member_ids_0'
  end

  def self.dependent_1_checkbox
    '#family_member_ids_1'
  end

  def self.employer_sponsored_benefits_radio_btn
    'label[for="market_kind_shop"] span'
  end

  def self.individual_benefits_radiobtn
    'label[for="market_kind_individual"] span'
  end

  def self.health_radio_btn
    'label[for="coverage_kind_health"] span'
  end

  def self.dental_radio_btn
    'label[for="coverage_kind_dental"] span'
  end

  def self.shop_for_new_plan_btn
    '.interaction-click-control-shop-for-new-plan'
  end

  def self.keep_existing_btn
    '.interaction-click-control-keep-existing-plan'
  end

  def self.select_plan_to_terminate_btn
    '.interaction-click-control-select-plan-to-terminate'
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
