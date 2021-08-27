# frozen_string_literal: true

module Events
  module Json
      # This class will register event
    class Stream < EventSource::Event
      publisher_path 'publishers.json_publisher'
    end
  end
end