# frozen_string_literal: true

module Events
  module IrsGroups
    # This class will register event
    class BuiltRequestedSeed < EventSource::Event
      publisher_path 'publishers.irs_groups.requested_seed_publisher'
    end
  end
end