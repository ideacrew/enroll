# frozen_string_literal: true

module Parties
  module Person
    class Updated < EventSource::Event
      publisher_key 'parties.person_publisher'
      attribute_keys :data, :metadata

    end
  end
end
