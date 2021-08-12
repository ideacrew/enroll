# frozen_string_literal: true

module Events
  module Fdsh
    module Esi
      module H14
        # This class will register event
        class DetermineEsiMecEligibility < EventSource::Event
          publisher_path 'publishers.esi_mec_publisher'

        end
      end
    end
  end
end