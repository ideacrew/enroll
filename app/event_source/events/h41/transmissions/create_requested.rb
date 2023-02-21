# frozen_string_literal: true

module Events
  module H41
    module Transmissions
      # This class will register event
      class  CreateRequested < EventSource::Event
        publisher_path 'publishers.h41.transmissions_publisher'
      end
    end
  end
end
