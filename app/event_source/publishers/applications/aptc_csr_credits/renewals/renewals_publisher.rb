# frozen_string_literal: true

module Publishers
  module Applications
    module AptcCsrCredits
      module Renewals
        # Publisher will send renewal and determination events
        class RenewalsPublisher
          include ::EventSource::Publisher[amqp: 'enroll.applications.aptc_csr_credits.renewals']

          register_event 'renewed'
          register_event 'determination_requested'
          register_event 'determination_added'
        end
      end
    end
  end
end
