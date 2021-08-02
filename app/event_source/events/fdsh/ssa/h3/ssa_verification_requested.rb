# frozen_string_literal: true

module Events
  module Fdsh
    module Ssa
      module H3
        # This class will register event
        class SsaVerificationRequested < EventSource::Event
          publisher_path 'publishers.ssa_verification_publisher'

        end
      end
    end
  end
end