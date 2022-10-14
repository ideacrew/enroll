# frozen_string_literal: true

module Events
  module Applications
    module AptcCsrCredits
      module Renewals
        module Notice
          class DeterminedMedicaidChipEligible < EventSource::Event
            publisher_path 'publishers.applications.aptc_csr_credits.renewals.notice_publisher'
          end
        end
      end
    end
  end
end