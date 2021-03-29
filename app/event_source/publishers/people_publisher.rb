# frozen_string_literal: true

module Publishers
  class PeoplePublisher
    include EventSource::Publisher['people_publisher']

    register_event 'people.person_updated'
  end
end
