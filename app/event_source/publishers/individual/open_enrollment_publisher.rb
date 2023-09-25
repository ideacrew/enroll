# frozen_string_literal: true

module Publishers
  module Individual
    # Publishes IVL open enrollment events
    class OpenEnrollmentPublisher
      include ::EventSource::Publisher[amqp: 'enroll.individual.open_enrollment']

      register_event 'begin'
    end
  end
end
