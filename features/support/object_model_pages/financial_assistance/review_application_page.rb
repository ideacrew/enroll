# frozen_string_literal: true

module FinancialAssistance
  class ReviewApplicationPage

    def self.need_help_paying_bills
    	'[data-cucumber="need-help-paying-bills"]'
    end

    def self.applicant_paying_bills
      '.applicant-paying-bills'
    end
  end
end
