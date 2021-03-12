# frozen_string_literal: true

class Adapters::RailsAdapter < EventSource::Adapter

  def enabled!
  	require 'active_support/notifications'
    # called the first time we know we are using this adapter
    # it would be a good spot to require the libraries you're using
    # and modify EventSource::Worker as needed
    # raise NotImplementedError
  end

  # example event  'ea.person.created'
  def enqueue(event)
    ActiveSupport::Notifications.instrument event.payload[:metadata][:event_key], event.payload
  end

  def dequeue(queue, key, matcher_hash, block)
    ActiveSupport::Notifications.subscribe(key) do |name, started, finished, unique_id, data|
      block.call(data)
    end
  end
end



