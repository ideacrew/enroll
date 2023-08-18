# frozen_string_literal: true

module Events
  module Applications
    module AptcCsrCredits
      module Renewals
        # This class has publisher's path for registering relevant events
        class DeterminationAdded < EventSource::Event
          publisher_path 'publishers.applications.aptc_csr_credits.renewals.renewals_publisher'

        end
      end
    end
  end
end

