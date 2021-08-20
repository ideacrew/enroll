# frozen_string_literal: true

module Events
  module Iap
    module Applications
      # This class will register event 'generate_renewal_draft'
      class GenerateRenewalDraft < EventSource::Event
        publisher_path 'publishers.application_publisher'

      end
    end
  end
end