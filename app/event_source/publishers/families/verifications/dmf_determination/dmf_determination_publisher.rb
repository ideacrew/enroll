# frozen_string_literal: true

module Publishers
  module Families
    module Verifications
      # Publisher for dmf_determination-related events
      class DmfDeterminationPublisher
        include ::EventSource::Publisher[amqp: 'enroll.families.verifications.dmf_determination']

        register_event 'started'
        register_event 'requested'
      end
    end
  end
end