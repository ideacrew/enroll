# frozen_string_literal: true

module Events
  # This class will register event
  class PersonSaved < EventSource::Event
    publisher_path 'publishers.people_publisher'
  end
end
