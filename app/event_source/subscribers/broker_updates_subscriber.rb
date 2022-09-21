# frozen_string_literal: true

module Subscribers
  # Subscriber for broker hired or fired events
  class BrokerUpdatesSubscriber
    include ::EventSource::Subscriber[amqp: 'enroll.family.brokers']

    subscribe(:on_broker_hired) do |delivery_info, _metadata, response|
    end

    subscribe(:on_broker_fired) do |delivery_info, _metadata, response|
    end
  end
end
