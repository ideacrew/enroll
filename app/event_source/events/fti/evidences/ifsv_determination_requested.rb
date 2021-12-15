# frozen_string_literal: true

module Events
  module Fti
    module Evidences
      # This class will register event
      class IfsvDeterminationRequested < EventSource::Event
        publisher_path 'publishers.fti.evidence_publisher'

      end
    end
  end
end