# frozen_string_literal: true

module Events
  module Private
    module Families
      # This class has publisher's path for registering relevant events
      class ValidateCvRequested < EventSource::Event

        publisher_path 'publishers.private.families.validate_cv_requested_publisher'
      end
    end
  end
end
