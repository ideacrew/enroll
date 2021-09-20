# frozen_string_literal: true

module Events
  module Iap
    module MecCheck
    # This class will register event
      class MecCheckRequested < EventSource::Event
        publisher_path 'publishers.mec_check_publisher'
      end
    end
  end
end