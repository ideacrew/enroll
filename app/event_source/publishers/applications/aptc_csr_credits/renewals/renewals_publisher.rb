# frozen_string_literal: true

module Publishers
  module Applications
    module AptcCsrCredits
      module Renewals
    # Publisher will send request payload to medicaid gateway for determinations
        class RenewalsPublisher
          include ::EventSource::Publisher[amqp: 'enroll.applications.aptc_csr_credits.renewals']

          # This event is to generate renewal draft applications
          register_event 'renewal_requested' # query families eligible for renewals
          register_event 'renewed'
          register_event 'determination_submission_requested'
          register_event 'determination_requested'
          register_event 'determination_added'
          register_event 'determination_notice_requested'
        end
      end
    end
  end
end
