# frozen_string_literal: true

module Events
  module Fdsh
    module Esi
      module H14
        # This class will register event
        class DetermineIfsvEligibility < EventSource::Event
          publisher_path 'publishers.ifsv_publisher'

        end
      end
    end
  end
end