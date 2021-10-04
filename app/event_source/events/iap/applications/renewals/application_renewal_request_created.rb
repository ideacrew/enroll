# frozen_string_literal: true

module Events
  module Iap
    module Applications
      module Renewals
        # This class will register event 'application_renewal_request_created'
        class ApplicationRenewalRequestCreated < EventSource::Event
          publisher_path 'publishers.application_renewal_request_created_publisher'

        end
      end
    end
  end
end



