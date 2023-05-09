# frozen_string_literal: true

module Events
  module AuditLog
      # This class will register created event
    class Created < EventSource::Event
      publisher_path 'publishers.audit_log_events_publisher'

    end
  end
end
