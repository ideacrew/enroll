if defined?(NewRelic)
  require 'new_relic/agent/method_tracer'
  Acapi::Publishers::UpstreamEventPublisher.class_eval do
    include ::NewRelic::Agent::MethodTracer
    add_method_tracer :handle_message
  end
end

listener = Acapi::Publishers::UpstreamEventPublisher.new
listener.register_subscribers!
listener.run
