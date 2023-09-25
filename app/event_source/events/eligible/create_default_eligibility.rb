# frozen_string_literal: true

module Events
  module Eligible
    # This class will register event
    class CreateDefaultEligibility < EventSource::Event
      publisher_path 'publishers.eligible.eligibility_publisher'
    end
  end
end
