remote_broker_uri = Rails.application.config.acapi.remote_broker_uri
hbx_id = Rails.application.config.acapi.hbx_id
environment = Rails.application.config.acapi.environment_name
target_exchange = "#{hbx_id}.#{environment}.e.fanout.events"
current_date = Date.today.strftime("%Y-%m-%d") 
event_routing_key = "info.events.calendar.date_change"

conn = Bunny.new(remote_broker_uri, :heartbeat => 15)
conn.start
chan = conn.create_channel
chan.confirm_select
ex = chan.fanout(target_exchange, :durable => true)
ex.publish("", { :routing_key => event_routing_key, :headers => { "current_date" => current_date }})
chan.wait_for_confirms
conn.close
