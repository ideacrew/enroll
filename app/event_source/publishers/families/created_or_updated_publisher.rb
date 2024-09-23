# frozen_string_literal: true

module Publishers
  module Families
    class CreatedOrUpdatedPublisher
      include ::EventSource::Publisher[amqp: 'enroll.families']

      register_event 'created_or_updated'
    end
  end
end
