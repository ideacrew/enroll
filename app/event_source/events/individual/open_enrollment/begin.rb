# frozen_string_literal: true

module Events
  module Individual
    module OpenEnrollment
      # This class will register event
      class Begin < EventSource::Event
        publisher_path 'publishers.individual.open_enrollment_publisher'
      end
    end
  end
end
