# frozen_string_literal: true

module Events
  module Individual
    module ConsumerRoles
      module LawfulPresenceDeterminations
        # This class will register event
        class Updated < EventSource::Event
          publisher_path 'publishers.lawful_presence_determinations_publisher'
        end
      end
    end
  end
end
