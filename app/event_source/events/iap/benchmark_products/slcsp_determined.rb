# frozen_string_literal: true

module Events
  module Iap
    module BenchmarkProducts
    # This class will register event
      class SlcspDetermined < EventSource::Event
        publisher_path 'publishers.iap.slcsp_determined_publisher'
      end
    end
  end
end
