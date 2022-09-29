# frozen_string_literal: true

module Publishers
  module Applications
    module AptcCsrCredits
      module Renewals
    # Publisher will send request payload to medicaid gateway for determinations
          class DeterminationSubmissionRequestedPublisher
            include ::EventSource::Publisher[amqp: 'enroll.applications.aptc_csr_credits.renewals.determination_submission_requested']

            # This event is to generate renewal draft applications
            register_event 'all'
          end
        end
    end
  end
end
