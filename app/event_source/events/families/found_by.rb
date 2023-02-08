# frozen_string_literal: true

module Events
  module Families
    # This class has publisher path to register event
    class FoundBy < EventSource::Event
      publisher_path 'publishers.families.found_by_publisher'
    end
  end
end
