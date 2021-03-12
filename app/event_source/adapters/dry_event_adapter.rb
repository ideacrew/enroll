# frozen_string_literal: true

class Adapters::DryEventAdapter < EventSource::Adapter

  def enabled!
  	require 'active_support/notifications'
    # called the first time we know we are using this adapter
    # it would be a good spot to require the libraries you're using
    # and modify EventSource::Worker as needed
    # raise NotImplementedError
  end

  # example event  'ea.person.created'
  def enqueue(event)
    publisher = event.publisher_class
    publisher.publish(event.event_key, event.payload)
  end

  def dequeue(queue, key, matcher_hash, block)

    # queue -> publisher key
    # key   -> event_key
    # matcher_hash -> {}

    publisher = event.publisher_class
    publisher.subscribe(event.event_key)
  end
end