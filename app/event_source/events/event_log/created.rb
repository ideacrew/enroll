# frozen_string_literal: true

module Events
  module EventLog
      # This class will register created event
    class Created < EventSource::Event
      publisher_path 'publishers.event_log_publisher'
      event_log_message_enabled true

    end
  end
end
