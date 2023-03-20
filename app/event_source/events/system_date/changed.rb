# frozen_string_literal: true

module Events
  module SystemDate
    # This class will register event
    class Changed < EventSource::Event
      publisher_path 'publishers.system_date.changed_publisher'
    end
  end
end
