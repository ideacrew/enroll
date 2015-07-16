listener = Acapi::Publishers::UpstreamEventPublisher.new
listener.register_subscribers!
listener.run
