# frozen_string_literal: true

class ChoosePlan

  include RSpec::Matchers
  include Capybara::DSL
    
  def find_your_doctor_link
    '//a[@class="interaction-click-control-find-your-doctor"]'
  end

  def estimate_your_cost_link
    '//a[@class="interaction-click-control-estimate-your-cost"]'
  end

  def plan_name_btn
    '//a[@class="btn btn-default interaction-click-control-plan-name"]'
  end

  def premium_amount_btn
    '//a[@class="btn btn-default interaction-click-control-premium-amount"]'
  end

  def deductible_btn
    '//a[@class="btn btn-default interaction-click-control-deductible"]'
  end

  def carrier_btn
    '//a[@class="btn btn-default interaction-click-control-carrier"]'
  end

  def carrier_dropdown
    '//select[@id="carrier"]'
  end

  def hsa_eligible_dropdown
    '//select[@id="hsa_eligibility"]'
  end

  def from_premium_amount
    '//input[@class="plan-metal-premium-from-selection-filter form-control"]'
  end

  def to_premium_amount
    '//input[@class="plan-metal-premium-to-selection-filter form-control fr"]'
  end

  def from_deductible_amount
    '//input[@class="plan-metal-deductible-from-selection-filter form-control"]'
  end

  def to_deductible_amount
    '//input[@class="plan-metal-deductible-to-selection-filter form-control"]'
  end

  def apply_btn
    '//a[@class="btn btn-primary apply-btn mz interaction-click-control-apply"]'
  end

  def reset_btn
    '//a[@class="btn btn-default reset-btn interaction-click-control-reset"]'
  end

  def select_plan_btn
    '(//a[@class="btn btn-default btn-right plan-select select"])[1]'
  end

  def see_details_btn
    '(//a[@class="btn btn-default"])[1]'
  end
end