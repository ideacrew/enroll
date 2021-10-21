# frozen_string_literal: true

module Events
  module Fdsh
    module Vlp
      module H92
        # This class will register event
        class InitialVerificationRequested < EventSource::Event
          publisher_path 'publishers.vlp_verification_publisher'

        end
      end
    end
  end
end