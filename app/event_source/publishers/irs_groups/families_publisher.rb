# frozen_string_literal: true

module Publishers
  module IrsGroups
    # Publisher will send request payload to enroll
    class FamiliesPublisher
      include ::EventSource::Publisher[amqp: 'irs_groups.families']

      register_event 'family_found'
    end
  end
end
