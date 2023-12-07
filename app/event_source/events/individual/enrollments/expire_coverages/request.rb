# frozen_string_literal: true

module Events
  module Individual
    module Enrollments
      module ExpireCoverages
      # Registers event for requesting IVL enrollment expirations
        class  Request < EventSource::Event
          publisher_path 'publishers.individual.enrollments.expire_coverages_publisher'
        end
      end
    end
  end
end