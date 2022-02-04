# frozen_string_literal: true

#insured/plan_shoppings/6047a0dc15484347455e41d9?coverage_kind=health&enrollment_kind=&market_kind=shop
class EmployeeChoosePlan

  def self.find_your_doctor_link
    '.interaction-click-control-find-your-doctor'
  end

  def self.estimate_your_costs_link
    '.interaction-click-control-estimate-your-costs'
  end

  def self.bronze_checkbox
    'label[for="plan-metal-level-bronze"]'
  end

  def self.silver_checkbox
    'label[for="plan-metal-level-silver"]'
  end

  def self.gold_checkbox
    'label[for="plan-metal-level-gold"]'
  end

  def self.platinum_checkbox
    'label[for="plan-metal-level-platinum"]'
  end

  def self.hmo_checkbox
    'label[for="checkbox-10"]'
  end

  def self.epo_checkbox
    'label[for="checkbox-11"]'
  end

  def self.pos_checkbox
    'label[for="checkbox-12"]'
  end

  def self.nationwide
    'label[for="checkbox-15"]'
  end

  def self.dc_metro
    'label[for="checkbox-16"]'
  end

  def self.carrier_dropdown
    '.interaction-choice-control-carrier'
  end

  def self.hsa_eligible_dropdown
    'hsa_eligibility'
  end

  def self.plan_name_btn
    '.interaction-click-control-plan-name'
  end

  def self.premium_amount_btn
    '.interaction-click-control-premium-amount'
  end

  def self.deductible_btn
    '.interaction-click-control-deductible'
  end

  def self.carrier_btn
    '.interaction-click-control-carrier'
  end

  def self.apply_btn
    '.interaction-click-control-apply'
  end

  def self.reset_btn
    '#reset-btn'
  end

  def self.select_plan_btn
    '.interaction-click-control-select-plan'
  end

  def self.see_details_btn
    '.interaction-click-control-see-details'
  end

  def self.continue_btn
    '.interaction-click-control-continue'
  end

  def self.waive_coverage
    '.interaction-click-control-waive-coverage'
  end

  def self.previous_link
    '.interaction-click-control-previous'
  end

  def self.save_and_exit_link
    '.interaction-click-control-save---exit'
  end

  def self.plan_count
    '[data-cuke="plan-count"]'
  end
end
