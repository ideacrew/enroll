# frozen_string_literal: true

module Events
  module BenefitSponsors
    module BenefitApplications
      # This class will register event 'open_enrollment_began_publisher'
      class OpenEnrollmentBegan < EventSource::Event
        publisher_path 'publishers.open_enrollment_began_publisher'

      end
    end
  end
end
