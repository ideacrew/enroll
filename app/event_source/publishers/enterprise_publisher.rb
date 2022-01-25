# frozen_string_literal: true

module Publishers
  # Publisher will send request payload to medicaid gateway for determinations
  class EnterprisePublisher
    include ::EventSource::Publisher[amqp: 'enroll.enterprise.events']

    register_event 'date_advanced'
    register_event 'document_reminder_notices_processed'
  end
end
