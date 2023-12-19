# frozen_string_literal: true

module Publishers
  # Publisher will publish audit log events
  class EventLogPublisher
    include ::EventSource::Publisher[amqp: 'enroll.event_log.events']

    register_event 'created'
  end
end
