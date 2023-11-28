# frozen_string_literal: true

module Events
  module Iap
    module AccountTransfers
      # This class will register event 'account_transfer_requested' for IAP Account Transfer
      class Requested < EventSource::Event
        publisher_path 'publishers.iap.account_transfer_publisher'
      end
    end
  end
end

