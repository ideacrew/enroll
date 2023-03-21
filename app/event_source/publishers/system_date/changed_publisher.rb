# frozen_string_literal: true

module Publishers
  module SystemDate
    # This class will resister event 'enroll.system_date.changed'
    class ChangedPublisher
      include ::EventSource::Publisher[amqp: 'enroll.system_date']

      register_event 'changed'
    end
  end
end
