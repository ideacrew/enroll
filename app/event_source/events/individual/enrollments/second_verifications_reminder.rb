# frozen_string_literal: true

module Events
  module Individual
    module Enrollments
      # This class will register event
      class  SecondVerificationsReminder < EventSource::Event
        publisher_path 'publishers.verifications_reminder_publisher'
      end
    end
  end
end