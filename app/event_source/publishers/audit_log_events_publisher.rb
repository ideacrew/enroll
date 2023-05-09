# frozen_string_literal: true

module Publishers
  # Publisher will publish audit log events
  class AuditLogEventsPublisher
    include ::EventSource::Publisher[amqp: 'enroll.audit_log.events']

    register_event 'created'
  end
end
