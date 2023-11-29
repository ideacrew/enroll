# frozen_string_literal: true

module Publishers
  module Individual
    module Enrollments
      # This class will register events for requesting expiration of IVL enrollments
      class ExpireCoveragesPublisher < EventSource::Event
        include ::EventSource::Publisher[amqp: 'enroll.individual.enrollments.expire_coverages']

        register_event 'request'

      end
    end
  end
end
