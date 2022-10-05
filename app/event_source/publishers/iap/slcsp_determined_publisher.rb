# frozen_string_literal: true

module Publishers
  module Iap
    # Publishes Benchmark Products SLCSP Determined event
    class SlcspDeterminedPublisher
      include ::EventSource::Publisher[amqp: 'enroll.iap.benchmark_products']

      register_event 'slcsp_determined'
    end
  end
end
