# frozen_string_literal: true

module Events
  module Fdsh
    module Ridp
      # This class will register event
      class SecondaryDeterminationRequested < EventSource::Event
        publisher_path 'publishers.ridp_eligibility_publisher'

      end
    end
  end
end