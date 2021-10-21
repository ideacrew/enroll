# frozen_string_literal: true

module Events
  module Fdsh
    module NonEsi
      module H31
        # This class will register event
        class DetermineNonEsiMecEligibility < EventSource::Event
          publisher_path 'publishers.non_esi_mec_publisher'

        end
      end
    end
  end
end