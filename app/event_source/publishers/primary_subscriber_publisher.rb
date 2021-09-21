# frozen_string_literal: true

module Publishers
  # Publishes changes to Primary Subscriber to CRM Gateway
  class PrimarySubscriberPublisher
    include ::EventSource::Publisher[amqp: 'crm_gateway.people']

    register_event 'primary_subscriber_update'
  end
end