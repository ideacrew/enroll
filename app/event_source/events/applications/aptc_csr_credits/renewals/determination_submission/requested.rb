# frozen_string_literal: true

module Events
  module Applications
    module AptcCsrCredits
      module Renewals
        module DeterminationSubmission
          # This class has publisher's path for registering relevant events
          class Requested < EventSource::Event
            publisher_path 'publishers.applications.aptc_csr_credits.renewals.determination_submission_requested_publisher'

          end
        end
      end
    end
  end
end

