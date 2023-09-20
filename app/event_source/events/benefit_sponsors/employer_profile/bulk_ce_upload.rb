# frozen_string_literal: true

module Events
  module BenefitSponsors
    module EmployerProfile
      # This class will register event 'employer_profile_publisher'
      class BulkCeUpload < EventSource::Event
        publisher_path 'publishers.benefit_sponsors.employer_profile_publisher'

      end
    end
  end
end
