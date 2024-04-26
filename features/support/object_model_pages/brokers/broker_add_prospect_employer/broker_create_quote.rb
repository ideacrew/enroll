# frozen_string_literal: true

#sponsored_benefits/organizations/plan_design_organizations/60e4568a1548433bc445cf0d/plan_design_proposals/new?profile_id=60e4460a297c6a786b63dd0d
class BrokerCreateQuotePage

  def self.quote_name
    'forms_plan_design_proposal[title]'
  end

  def self.select_start_on_dropdown
    'div.selectric span'
  end

  def self.select_start_on_date
    'li[data-index="1"]'
  end

  def self.add_employee_btn
    '.btn.btn-default.pull-right.interaction-click-control-add-employee'
  end

  def self.upload_employee_roster_btn
    '.btn.btn-default.interaction-click-control-upload-employee-roster'
  end

  def self.return_to_quote_management_btn
    '.btn.btn-primary.interaction-click-control-return-to-quote-management'
  end

  def self.select_health_benefits_btn
    '.interaction-click-control-select-health-benefits'
  end

  def self.download_employee_roster_btn
    '.download-employees.btn.btn-default.interaction-click-control-download-employee-roster'
  end

  def self.show_employee_details
    '.interaction-click-control-show-details'
  end

  def self.reference_plan_radio
    '.col-xs-12.reference-plan'
  end

  def self.back_to_all_quotes
    "[data-cuke='back_to_all_quotes']"
  end

  def self.quote_hc4cc_eligibility
    'tbody .col-hc4cc'
  end

  def self.osse_subsidy_radio_true
    '#forms_plan_design_proposal_osse_eligibility_true'
  end

  def self.osse_subsidy_radio_false
    '#forms_plan_design_proposal_osse_eligibility_false'
  end
end
