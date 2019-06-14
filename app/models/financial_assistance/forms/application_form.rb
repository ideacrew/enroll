# frozen_string_literal: true

module FinancialAssistance
  module Forms
    class ApplicationForm
      include Virtus.model

      attribute :applicants, Array[ApplicantForm]

      attribute :id, String
      attribute :is_requesting_voter_registration_application_in_mail, Boolean
      attribute :years_to_renew, Integer
      attribute :parent_living_out_of_home_terms, Integer

      def active_applicants
        applicants.inject([]) do |arr, applicant|
          arr << applicant if applicant.is_active
          arr
        end
      end
    end
  end
end
