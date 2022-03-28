# frozen_string_literal: true

#families/home
class EmployeeHomepage

  def self.my_dc_health_link
    '.interaction-click-control-my-dc-health-link'
  end

  def self.my_broker_link
    '.interaction-click-control-my-broker'
  end

  def self.documents_link
    'interaction-click-control-documents'
  end

  def self.cost_savings_link
    'interaction-click-control-cost-savings'
  end

  def self.messages_link
    'a[class^="interaction-click-control-messages"]'
  end

  def self.manage_family_btn
    '.interaction-click-control-manage-family'
  end

  def self.actions_dropdown
    '#dropdownMenuButton'
  end

  def self.view_my_coverage_btn
    '.interaction-click-control-view-my-coverage-details'
  end

  def self.make_changes_btn
    '.interaction-click-control-make-changes-to-my-coverage'
  end

  def self.shop_for_plans_btn
    '.interaction-click-control-shop-for-plans'
  end

  def self.qle_continue_btn
    '#qle_submit'
  end

  def self.enrollment_tobacco_use
    '[data-cuke="tobbaco_use"]'
  end

  def self.enrollment_coverage_state_date
    '[data-cuke="enrollment_coverage_state_date"]'
  end
end