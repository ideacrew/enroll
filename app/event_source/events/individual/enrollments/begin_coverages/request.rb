# frozen_string_literal: true

module Events
  module Individual
    module Enrollments
      module BeginCoverages
      # Registers event for requesting initiation of IVL enrollment coverages
        class Request < EventSource::Event
          publisher_path 'publishers.individual.enrollments.begin_coverages_publisher'
        end
      end
    end
  end
end