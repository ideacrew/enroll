# frozen_string_literal: true

#families/home
class IvlHomepage

  def self.my_dc_health_link
    '.interaction-click-control-my-dc-health-link'
  end

  def self.documents_link
    '.interaction-click-control-documents'
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

  def self.make_changes_btn
    '.interaction-click-control-make-changes, .interaction-click-control-make-changes-to-my-coverage'
  end

  def self.view_details_btn
    '.interaction-click-control-view-details'
  end

  def self.shop_for_plans
    '.interaction-click-control-shop-for-plans'
  end

  def self.medicaid_and_tax_credits_btn
    '.interaction-click-control-go-to-district-direct'
  end

  def self.help_signing_up_btn
    '.interaction-click-control-get-help-signing-up'
  end

  def self.covid_link
    '.interaction-click-control-covid-19'
  end

  def self.had_a_baby_link
    '.interaction-click-control-had-a-baby'
  end

  def self.adopted_a_child_link
    '.interaction-click-control-adopted-a-child'
  end

  def self.married_link
    '.interaction-click-control-married'
  end

  def self.aptc_amount_text
    'APTC amount'
  end

  def self.actions_dropdwon
    '#dropdownMenuButton'
  end

  def self.view_my_coverage_btn
    '.interaction-click-control-view-my-coverage-details'
  end

  def self.make_payments_btn
    '.interaction-click-control-make-payments-for-my-plan'
  end

  def self.make_payments_btn_glossary
    '.interaction-click-control-make-payments-for-my-plan .hover-glossary'
  end

  def self.first_payment
    '.interaction-click-control-make-a-first-payment-for-my-new-plan'
  end

  def self.first_payment_glossary
    '.interaction-click-control-make-a-first-payment-for-my-new-plan .hover-glossary'
  end

  def self.enrollment_tobacco_use
    '[data-cuke="tobbaco_use"]'
  end

  def self.enrollment_coverage_state_date
    '[data-cuke="enrollment_coverage_state_date"]'
  end

  def self.enrollment_detail
    '[data-cuke="enrollment_detail"]'
  end

  def self.enrollment_member_detail
    '[data-cuke="enrollment_member_detail"]'
  end

  def self.select_this_broker
    '[data-cuke="select_this_broker"]'
  end
end
