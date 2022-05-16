# frozen_string_literal: true

module Events
  module Individual
    module ConsumerRoles
      # This class will register event
      class  Created < EventSource::Event
        publisher_path 'publishers.consumer_roles_publisher'
      end
    end
  end
end
