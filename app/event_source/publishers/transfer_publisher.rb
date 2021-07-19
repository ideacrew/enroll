# frozen_string_literal: true

module Publishers
  # Publisher will send request payload to medicaid gateway for determinations
  class TransferPublisher
    include ::EventSource::Publisher[amqp: 'enroll.iap.transfers']

    register_event 'transfer_account'
  end
end