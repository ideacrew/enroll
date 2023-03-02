# frozen_string_literal: true

module Events
  module H411095as
    # This class will register event
    class TransmissionRequested < EventSource::Event
      publisher_path 'publishers.h41_1095as.transmissions_publisher'
    end
  end
end
