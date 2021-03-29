# frozen_string_literal: true

module FinancialAssistance
  module Publishers
    class ApplicantsPublisher
      include ::EventSource::Publisher['financial_assistance.applicants_publisher']

      # Subscribers may register for block events directly in publisher class
      register_event 'applicants.applicant_created'
    end
  end
end