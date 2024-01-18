# frozen_string_literal: true

module Events
  module Fdsh
    module Vlp
      module Rx142
        # This class will register event
        class CloseCaseRequested < EventSource::Event
          publisher_path 'publishers.close_case_publisher'

        end
      end
    end
  end
end