# frozen_string_literal: true

require 'dry/events/publisher'

module Parties
  class PersonPublisher
    include Dry::Events::Publisher['parties.person_publisher']

    register_event 'parties.person.updated'
  end
end
