# frozen_string_literal: true

module Publishers
  module Private
    module Families
      # This class resisters event 'enroll.private.families.validate_cv_requested'
      class ValidateCvRequestedPublisher
        include ::EventSource::Publisher[amqp: 'enroll.private.families']

        register_event 'validate_cv_requested'
      end
    end
  end
end
