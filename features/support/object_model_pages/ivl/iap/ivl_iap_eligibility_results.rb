# frozen_string_literal: true

# Page Object Model class for Financial Assistance Eligibility Results
class IvlIapEligibilityResults
  def self.eligibility_results
    "[data-cuke='eligibility_results']"
  end

  def self.tax_household
    "[data-cuke='tax_household']"
  end

  def self.review_eligibility_header
    "[data-cuke='review_eligibility_header']"
  end

  def self.aptc_text
    "[data-cuke='aptc_text']"
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

  def self.medicaid_or_chip
    "[data-cuke='medicaid_or_chip']"
  end

  def self.medicaid_or_chip_text
    "[data-cuke='medicaid_or_chip_text']"
  end

  def self.private_health_insurance
    "[data-cuke='private_health_insurance']"
  end

  def self.private_health_insurance_text
    "[data-cuke='private_health_insurance_text']"
  end

  def self.does_not_qualify
    "[data-cuke='does_not_qualify']"
  end

  def self.does_not_qualify_text
    "[data-cuke='does_not_qualify_text']"
  end

  def self.referral
    "[data-cuke='referral']"
  end

  def self.qualified_reason
    "[data-cuke='qualified_reason']"
  end

  def self.next_steps
    "[data-cuke='next_steps']"
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
