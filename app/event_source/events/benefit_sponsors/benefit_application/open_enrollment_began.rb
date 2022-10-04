# frozen_string_literal: true

module Events
  module BenefitSponsors
    module BenefitApplication
      # This class will register event 'benefit_application_publisher'
      class OpenEnrollmentBegan < EventSource::Event
        publisher_path 'publishers.benefit_sponsors.benefit_application_publisher'

      end
    end
  end
end
