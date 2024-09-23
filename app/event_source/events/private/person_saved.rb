# frozen_string_literal: true

module Events
  module Private
    class PersonSaved < EventSource::Event
      publisher_path 'publishers.private.people_publisher'
    end
  end
end
