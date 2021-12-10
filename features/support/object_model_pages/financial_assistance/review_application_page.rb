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
  end
end
