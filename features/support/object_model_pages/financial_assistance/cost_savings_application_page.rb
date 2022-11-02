# frozen_string_literal: true

#dchbx.org
class CostSavingsApplicationPage

  def self.start_new_application_btn
    '.interaction-click-control-start-new-application'
  end

  def self.oe_application_warning_display
    "[data-cuke='oe_application_warning_display']"
  end

  def self.coverage_update_reminder_display
    "[data-cuke='coverage_update_reminder_display']"
  end

  def self.index_with_filter
    "[data-cuke='index_with_filter']"
  end

  def self.employer_sponsored_insurance_benefit_checkbox
    "[data-cuke='employer_sponsored_insurance_benefit_checkbox']"
  end

  def self.esi_benefit
    "[data-cuke='esi_benefit']"
  end

  def self.non_esi_benefit
    "[data-cuke='non_esi_benefit']"
  end

  def self.meets_mvs_and_affordable
    "[data-cuke='meets_mvs_and_affordable']"
  end

  def self.benefit_esi_ein_label
    "[data-cuke='benefit_esi_ein_label']"
  end
end
