# frozen_string_literal: true

module Events
  module Iap
    module Transfers
      # This class will register event
      class TransferredAccountResponse < EventSource::Event
        publisher_path 'publishers.transfer_publisher'

      end
    end
  end
end