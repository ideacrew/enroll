# frozen_string_literal: true

module Publishers
  module Families
    # This class will register event
    class FoundByPublisher
      include ::EventSource::Publisher[amqp: 'enroll.families']

      register_event 'found_by'
    end
  end
end
