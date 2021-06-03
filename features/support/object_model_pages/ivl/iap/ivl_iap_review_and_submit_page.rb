# frozen_string_literal: true

#financial_assistance/applications/consumer_role_id/review_and_submit
class IvlIapReviewAndSubmit

  def self.edit_income_and_deductions
    'a[id="edit-income-and-deductions-pencil"]'
  end

  def self.edit_tax_info
    'a[id="edit-tax-info-pencil"]'
  end

  def self.edit_income
    'a[id="edit-income-pencil"]'
  end

  def self.edit_income_adjustments
    'a[id="edit-income-adjustments-pencil"]'
  end

  def self.edit_health_coverage
    'a[id="edit-health-coverage-pencil"]'
  end

  def self.edit_other_questions
    'edit-other-questions-pencil'
  end

  def self.continue_btn
    'a[class="btn btn-lg btn-primary btn-block interaction-click-control-continue"]'
  end

  def self.eligibility_easier_no_radiobtn
    '#eligibility_easier_no'
  end

  def self.eligibility_easier_yes_radiobtn
    '#eligibility_easier_yes'
  end

  def self.register_to_vote_no_radiobtn
    'mailed_no'
  end

  def self.register_to_vote_yes_radiobtn
    'mailed_yes'
  end

  def self.continue
    'input[type="submit"]'
  end

  def self.agree_application_medicaid_terms_checkbox
    '#application_medicaid_terms'
  end

  def self.agree_application_report_change_terms_checkbox
    '#application_report_change_terms'
  end

  def self.agree_application_medicaid_insurance_collection_terms_checkbox
    '#application_medicaid_insurance_collection_terms'
  end

  def self.living_outside_no_radiobtn
    'living_outside_no'
  end

  def self.living_outside_yes_radiobtn
    'living_outside_yes'
  end

  def self.application_attestation_terms_checkbox
    'input[name="application[submission_terms]"]'
  end

  def self.application_submission_terms_checkbox
    '#application_submission_terms'
  end

  def self.medicaid_determination_no_radiobtn
    'medicaid_determination_no'
  end

  def self.medicaid_determination_yes_radiobtn
    'medicaid_determination_yes'
  end

  def self.first_name
    'first_name_thank_you'
  end

  def self.middle_name
    'middle_name_thank_you'
  end

  def self.last_name
    'last_name_thank_you'
  end

  def self.submit_application
    'input[class="btn btn-lg btn-primary interaction-click-control-submit-application"]'
  end
end