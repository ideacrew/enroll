# frozen_string_literal: true

module Events
  # This class will register event
  class EnrollmentSaved < EventSource::Event
    publisher_path 'publishers.enrollment_publisher'
  end
end
