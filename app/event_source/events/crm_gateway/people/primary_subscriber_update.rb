# frozen_string_literal: true

module Events
  module CrmGateway
    module People
      # This class will register event
      class PrimarySubscriberUpdate < EventSource::Event
        publisher_path 'publishers.primary_subscriber_publisher'
      end
    end
  end
end