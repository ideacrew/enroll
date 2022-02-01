# frozen_string_literal: true

module Events
  module Individual
    module Eligibilities
      module Application
        module Applicant
          # This class will register event
          class NonEsiMecEvidenceUpdated < EventSource::Event
            publisher_path 'publishers.aptc_csr_credit_eligibilities_publisher'
          end
        end
      end
    end
  end
end

