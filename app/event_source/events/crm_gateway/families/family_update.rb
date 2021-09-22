# frozen_string_literal: true

module Events
  module CrmGateway
    module Families
      # This class will register event
      class FamilyUpdate < EventSource::Event
        publisher_path 'publishers.family_publisher'
      end
    end
  end
end
