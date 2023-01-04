# frozen_string_literal: true

module Events
  module BenefitSponsors
    module NonCongressional
      module DependentAgeOffTermination
        # This class will register event 'dependent_age_off_termination.requested'
        class Requested < EventSource::Event
          publisher_path 'publishers.benefit_sponsors.non_congressional.dependent_age_off_termination_publisher'

        end
      end
    end
  end
end
