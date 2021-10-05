# frozen_string_literal: true

module Publishers
  # Publisher will send request payload to medicaid gateway to be transferred
  class TransferPublisher
    include ::EventSource::Publisher[amqp: 'enroll.iap.transfers']

    register_event 'transfer_account'

    register_event 'transferred_account_response'
  end
end