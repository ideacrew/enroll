# frozen_string_literal: true

module Events
  module H36
    # This class has publisher path to register event
    class TransmissionRequested < EventSource::Event
      publisher_path 'publishers.h36.transmissions_publisher'
    end
  end
end
