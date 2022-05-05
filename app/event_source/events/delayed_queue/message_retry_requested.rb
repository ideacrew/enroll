# frozen_string_literal: true

module Events
    module DelayedQueue
        # This class will register date change event
      class MessageRetryRequested < EventSource::Event
        publisher_path 'publishers.delayed_message_publisher'
  
      end
    end
end