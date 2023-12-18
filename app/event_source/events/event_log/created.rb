# frozen_string_literal: true

module Events
  module EventLog
      # This class will register created event
    class Created < EventSource::Event
      publisher_path 'publishers.event_log_publisher'

    end
  end
end
