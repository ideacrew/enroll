# frozen_string_literal: true

module Events
  module BatchProcess
    # This class will register date change event
    class BatchEventProcessRequested < EventSource::Event
      publisher_path "publishers.batch_process_publisher"
    end
  end
end
