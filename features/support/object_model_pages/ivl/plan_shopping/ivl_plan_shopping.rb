# frozen_string_literal: true

#Ivl plan shopping
class IvlPlanShopping
  def self.premium_amount_from_filter
    "input[type='text'][class='plan-metal-premium-from-selection-filter form-control']"
  end

  def self.premium_amount_to_filter
    "input[type='text'][class='plan-metal-premium-to-selection-filter form-control fr']"
  end

  def self.plans_count
    "Plans:   4"
  end

  def self.apply_button
    ".apply-btn"
  end
end
