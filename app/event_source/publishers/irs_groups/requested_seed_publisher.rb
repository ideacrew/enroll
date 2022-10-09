# frozen_string_literal: true

module Publishers
  module IrsGroups
    # Publisher will send request payload to enroll
    class RequestedSeedPublisher
      include ::EventSource::Publisher[amqp: 'irs_groups.seed_requested']

      register_event 'built_requested_seed'
    end
  end
end
