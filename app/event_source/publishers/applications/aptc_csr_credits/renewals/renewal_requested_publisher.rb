# frozen_string_literal: true

module Publishers
  module Applications
    module AptcCsrCredits
      module Renewals
        # Publisher will send request to EA to create renewal drafts
        class RenewalRequestedPublisher
          include ::EventSource::Publisher[amqp: 'enroll.applications.aptc_csr_credits.renewals.renewal']

          register_event 'requested'
        end
      end
    end
  end
end
