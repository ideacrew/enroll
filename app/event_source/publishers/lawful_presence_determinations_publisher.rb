# frozen_string_literal: true

module Publishers
  # Publisher will send request payload to enroll
  class LawfulPresenceDeterminationsPublisher
    include ::EventSource::Publisher[amqp: 'enroll.individual.consumer_roles.lawful_presence_determinations']

    register_event 'updated'
  end
end
