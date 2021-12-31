# frozen_string_literal: true

module Events
  module Individual
    module Accounts
      # This class will register event
      class  EsiEvidenceUpdated < EventSource::Event
        publisher_path 'publishers.aptc_csr_credit_eligibilities_publisher'
      end
    end
  end
end