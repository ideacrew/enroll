# frozen_string_literal: true

#financial_assistance/applications/consumer_role_id/applicants/consumer_role_id/step/1
class IvlIapTaxInformationPage

  def self.file_taxes_yes_radiobtn
    'is_required_to_file_taxes_yes'
  end

  def self.file_taxes_no_radiobtn
    if EnrollRegistry[:bs4_consumer_flow].enabled?
      '.interaction-choice-control-value-is-required-to-file-taxes-no'
    else
      'is_required_to_file_taxes_no'
    end
  end

  def self.not_sure_file_taxes_link
    'a[href="#is_required_to_file_taxes"]'
  end

  def self.claimed_as_tax_dependent_yes_radiobtn
    'is_claimed_as_tax_dependent_yes'
  end

  def self.claimed_as_tax_dependent_no_radiobtn
    if EnrollRegistry[:bs4_consumer_flow].enabled?
      '.interaction-choice-control-value-is-claimed-as-tax-dependent-no'
    else
      'is_claimed_as_tax_dependent_no'
    end
  end

  def self.not_sure_claimed_as_dependent_link
    'a[href="#is_claimed_as_tax_dependent"]'
  end

  def self.claimed_as_dependent_by_dropdown
    'div[class="selectric-wrapper selectric-form-control selectric-claimed-dependent-dropdown selectric-below"]'
  end

  def self.not_sure_claimed_as_dependent_by_link
    'a[href="#claimed_as_tax_dependent_by"]'
  end

  def self.continue_btn
    'input[id="btn-continue"]'
  end

  def self.help_me_sign_up_bttn
    'div[class="btn btn-default btn-block help-me-sign-up"]'
  end

  def self.back_to_all_household_members
    'a[class="interaction-click-control-back-to-all-household-members"]'
  end
end
