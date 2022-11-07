# frozen_string_literal: true

module Events
  module Applications
    module AptcCsrCredits
      module Renewals
        # This class will register event 'application_renewal_request_created'
        class Renewed < EventSource::Event
          publisher_path 'publishers.applications.aptc_csr_credits.renewals.renewals_publisher'

        end
      end
    end
  end
end

