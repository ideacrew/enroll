# frozen_string_literal: true

module Publishers
  module Individual
    module Enrollments
      # This class will register events for requesting beginning of IVL enrollments
      class BeginCoveragesPublisher < EventSource::Event
        include ::EventSource::Publisher[amqp: 'enroll.individual.enrollments.begin_coverages']

        register_event 'request'
        register_event 'begin'

      end
    end
  end
end
