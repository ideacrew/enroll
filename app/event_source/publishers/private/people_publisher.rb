# frozen_string_literal: true

module Publishers
    module Private
      class PeoplePublisher
        include ::EventSource::Publisher[amqp: 'enroll.private']
  
        register_event 'person_saved'
      end
    end
  end
  