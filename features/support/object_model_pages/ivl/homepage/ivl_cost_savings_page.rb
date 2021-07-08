# frozen_string_literal: true

#financial_assistance/applications?tab=cost_savings
class IvlCostSavings

  def self.actions_dropdown
    'button[id="dropdown_for_"]'
  end

  def self.select_copy_to_new_application
    'a[class="btn btn-xs interaction-click-control-copy-to-new-application"]'
  end

  def self.select_review_application
    'a[class="btn btn-xs interaction-click-control-review-application"]'
  end

  def self.select_full_application
    'a[class="btn btn-xs interaction-click-control-full-application"]'
  end

  def self.submit_new_application_btn
    'input[value="Start new application"]'
  end
end