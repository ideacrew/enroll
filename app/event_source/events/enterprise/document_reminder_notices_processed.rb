# frozen_string_literal: true

module Events
  module Enterprise
      # This class will register date change event
    class DocumentReminderNoticesProcessed < EventSource::Event
      publisher_path 'publishers.enterprise_publisher'

    end
  end
end
