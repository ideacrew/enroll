# frozen_string_literal: true

module Events
  module Fdsh
    module Evidences
      # This class will register event
      class NonEsiDeterminationRequested < EventSource::Event
        publisher_path 'publishers.fdsh.evidences.non_esi_determination_requested'

      end
    end
  end
end