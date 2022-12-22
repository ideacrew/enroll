# frozen_string_literal: true

module Publishers
  module BenefitSponsors
    module NonCongressional
      # This class will register event 'dependent_age_off_termination.requested'
      class DependentAgeOffTermination < EventSource::Event
        include ::EventSource::Publisher[amqp: 'enroll.benefit_sponsors.non_congressional.dependent_age_off_termination']

        register_event 'requested'
      end
    end
  end
end
