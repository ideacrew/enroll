# frozen_string_literal: true

module Subscribers
  class PersonSubscriber
    include EventSource::Subscriber

    subscription 'people_publisher', 'people.person_updated'

    def on_people_person_updated(attributes)
      puts "EA------------->>>>>person subscriber reached with #{attributes.inspect}"
      # heavy lifting
    end
  end
end
