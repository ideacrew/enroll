# frozen_string_literal: true

module Publishers
  module InsurancePolicies
    # This class will register event
    class RefreshRequestedPublisher
      include ::EventSource::Publisher[amqp: 'enroll.insurance_policies']

      register_event 'refresh_requested'
    end
  end
end
