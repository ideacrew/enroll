# frozen_string_literal: true

module Publishers
    # Publisher will send request payload to medicaid gateway for determinations
    class DelayedMessagePublisher
      include ::EventSource::Publisher[amqp: 'enroll.delayed_message.events']
  
      register_event 'message_retry_requested'
    end
  end
  