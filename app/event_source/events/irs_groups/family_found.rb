# frozen_string_literal: true

module Events
  module IrsGroups
    # This class will register event
    class FamilyFound < EventSource::Event
      publisher_path 'publishers.irs_groups.families_publisher'
    end
  end
end