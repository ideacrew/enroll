# frozen_string_literal: true

# Financial Assistance Review form
module FinancialAssistance
  # For Review Application page
  class ReviewApplicationPage

    def self.need_help_paying_bills
      '[data-cuke="need-help-paying-bills"]'
    end

    def self.applicant_paying_bills
      '[data-cuke="applicant-paying-bills"]'
    end

    def self.is_ssn_applied
      '[data-cuke="review_is_ssn_applied"]'
    end

    def self.non_ssn_apply_reason
      '[data-cuke="review_no_ssn_reason"]'
    end
  end
end
