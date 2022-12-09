# frozen_string_literal: true

module Events
  module Family
    module Brokers
      # This class will register event
      class BrokerFired < EventSource::Event
        publisher_path 'publishers.broker_updates_publisher'
      end
    end
  end
end
