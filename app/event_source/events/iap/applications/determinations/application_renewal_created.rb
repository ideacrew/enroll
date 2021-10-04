# frozen_string_literal: true

module Events
  module Iap
    module Applications
      module Determinations
        # This class will register event 'application_renewal_created'
        class ApplicationRenewalCreated < EventSource::Event
          publisher_path 'publishers.application_renewal_created_publisher'

        end
      end
    end
  end
end