# frozen_string_literal: true

module Events
  module Iap
    module Applications
      # This class will register event 'application_renewal_created'
      class ApplicationRenewalCreated < EventSource::Event
        publisher_path 'publishers.application_publisher'

      end
    end
  end
end