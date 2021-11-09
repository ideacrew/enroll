# frozen_string_literal: true

module Events
  module Individual
    module Notices
      # This class will register event
      class VerificationsReminder < EventSource::Event
        publisher_path 'publishers.notices_publisher'
      end
    end
  end
end
