event_source_root = Rails.root.join('app', 'event_source')

require "#{event_source_root}/adapters/rails_adapter.rb"
EventSource.adapter = ::Adapters::RailsAdapter.new unless EventSource.has_adapter?


# EventSource.add_adapter(:dry_event, ::Adapters::DryEventAdapter.new)
# EventSource.add_adapter(:active_support_notification, ::Adapters::RailsAdapter.new)
# EventSource.add_adapter(:amqp, ::Adapters::BunnyAdapter.new)


# EventSource.adapter_for(:amqp)



Dir["#{event_source_root}/publishers/parties/*.rb"].each {|file| require file }
EventSource::Publisher.register_publishers(event_source_root.join('publishers'))

Dir["#{event_source_root}/subscribers/parties/*.rb"].each {|file| require file }

EventSource.dispatch(:enroll) do
  subscribe 'financial_assistance.parties.applicant.created' do |attributes|
    ApplicantCreatedJob.perform_now(attributes)
  end
end


# Adapter
# 	- interfaces with the message transport

# 	methods:
# 	  enqueue
# 	  dequeue

# Dispatcher
# 	- route events onto adapters 

#     subscribe

# Publisher
#     - broadcast events to registered subscribers

# Subscription
#     - queue ?
#     - Listen and enables reactors to publisher shared events

# Reactor



# Dry Event Publisher
#    - publishes to subscribers
#    - publishes using ActiveSupport::Notifications

# Dry Event Subscriber
# ActiveSupport::Notifications Subscriber

# Reactor
#   Action taken inside of subscriber code block