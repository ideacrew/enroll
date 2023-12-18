# frozen_string_literal: true

module Events
  module Hc4cc
    # This class will register event
    class EligibilityCreated < EventSource::Event
      publisher_path 'publishers.hc4cc_eligibility_publisher'
    end
  end
end

