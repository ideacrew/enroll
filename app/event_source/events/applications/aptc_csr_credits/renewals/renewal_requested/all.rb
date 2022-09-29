# frozen_string_literal: true

module Events
  module Applications
    module AptcCsrCredits
      module Renewals
        module RenewalRequested
        # This class will register event 'application_renewal_request_created'
          class All < EventSource::Event
            publisher_path 'publishers.applications.aptc_csr_credits.renewals.renewal_requested_publisher'

          end
        end
      end
    end
  end
end

