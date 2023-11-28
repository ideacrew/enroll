# frozen_string_literal: true

module Publishers
  # Publisher will send batch requests
  class BatchProcessPublisher
    include ::EventSource::Publisher[amqp: "enroll.batch_process.events"]

    register_event "batch_events_requested"
    register_event "batch_event_process_requested"
  end
end
