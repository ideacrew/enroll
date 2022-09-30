# frozen_string_literal: true

module Publishers
  module Applications
    module AptcCsrCredits
      module Renewals
        # Publisher will send request to EA for application submissions and determinations
        class DeterminationSubmissionRequestedPublisher
          include ::EventSource::Publisher[amqp: 'enroll.applications.aptc_csr_credits.renewals.determination_submission']

          register_event 'requested'
        end
      end
    end
  end
end
