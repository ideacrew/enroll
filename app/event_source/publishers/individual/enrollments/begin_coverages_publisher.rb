# frozen_string_literal: true

module Publishers
  module Individual
    module Enrollments
      # This class will register events for requesting beginning of IVL enrollments
      class BeginCoveragesPublisher < EventSource::Event
        include ::EventSource::Publisher[amqp: 'enroll.individual.enrollments.begin_coverages']

        register_event 'request'

      end
    end
  end
end
