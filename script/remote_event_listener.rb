listener_class = Acapi::Publishers::UpstreamEventPublisher 

if defined?(NewRelic)
  Acapi::Publishers::UpstreamEventPublisher.class_eval do
    include NewRelic::Agent::Instrumentation::ControllerInstrumentation
    add_transaction_tracer :handle_message, :category => :task
  end
end

listener = listener_class.new
listener.register_subscribers!
listener.run
