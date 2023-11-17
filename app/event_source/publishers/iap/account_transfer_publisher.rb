# frozen_string_literal: true

module Publishers
  module Iap
    # This class will register event 'requested'
    class AccountTransferPublisher < EventSource::Event
      include ::EventSource::Publisher[amqp: 'enroll.iap.account_transfers']

      register_event 'requested'
    end
  end
end

