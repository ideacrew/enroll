# frozen_string_literal: true

module Events
  module Enterprise
    # This class will register event
    class DateAdvanced < EventSource::Event
      publisher_path 'publishers.enroll_enterprise_publisher'

    end
  end
end
