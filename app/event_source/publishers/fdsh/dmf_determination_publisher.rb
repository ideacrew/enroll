# frozen_string_literal: true

module Publishers
  module Fdsh
    # Publisher will send request payload to FDSH gateway for DMF
    class DmfDeterminationPublisher
      include ::EventSource::Publisher[amqp: 'fdsh.families.verifications.dmf_determination']

      register_event 'requested'
    end
  end
end