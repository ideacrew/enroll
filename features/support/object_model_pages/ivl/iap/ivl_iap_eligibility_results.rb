# frozen_string_literal: true

# Page Object Model class for Financial Assistance Eligibility Results
class IvlIapEligibilityResults
  def self.eligibility_results
    "[data-cuke='eligibility_results']"
  end

  def self.tax_household
    "[data-cuke='tax_household']"
  end

  def self.aptc_heading
    "[data-cuke='aptc_heading']"
  end

  def self.aptc_text
    "[data-cuke='aptc_text']"
  end

  def self.csr_73_87_or_94_text
    "[data-cuke='csr_73_87_or_94_text']"
  end

  def self.full_name
    "[data-cuke='full_name']"
  end

  def self.csr
    "[data-cuke='csr']"
  end

  def self.csr_text
    "[data-cuke='csr_text']"
  end

  def self.medicaid_or_chip_heading
    "[data-cuke='medicaid_or_chip_heading']"
  end

  def self.medicaid_or_chip_text
    "[data-cuke='medicaid_or_chip_text']"
  end

  def self.uqhp_heading
    "[data-cuke='uqhp_heading']"
  end

  def self.uqhp_text
    "[data-cuke='uqhp_text']"
  end

  def self.totally_ineligible_heading
    "[data-cuke='totally_ineligible_heading']"
  end

  def self.totally_ineligible_text
    "[data-cuke='totally_ineligible_text']"
  end

  def self.non_magi_referral_heading
    "[data-cuke='non_magi_referral_heading']"
  end

  def self.non_magi_referral_text
    "[data-cuke='non_magi_referral_text']"
  end

  def self.next_steps
    "[data-cuke='next_steps']"
  end

  def self.all_medicaid_next_steps_continue_text
    "[data-cuke='all_medicaid_next_steps_continue_text']"
  end

  def self.next_steps_text
    "[data-cuke='next_steps_text']"
  end

  def self.return_to_account_home
    "[data-cuke='return_to_account_home']"
  end

  def self.continue_text
    "[data-cuke='continue_text']"
  end

  def self.your_application_reference_2
    "[data-cuke='your_application_reference_2']"
  end

  def self.other_actions
    "[data-cuke='other_actions']"
  end
end
