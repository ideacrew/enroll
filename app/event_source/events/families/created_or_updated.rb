# frozen_string_literal: true

module Events
  module Families
    class CreatedOrUpdated < EventSource::Event
      publisher_path 'publishers.families.created_or_updated_publisher'
    end
end
end