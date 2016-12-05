module Subscribers
  class NotificationSubscriber < ::Acapi::Subscription
    include Acapi::Notifiers

    def self.subscription_details
      ["acapi.info.events.employer.planyear_renewal_3a"]
    end

    def call(event_name, e_start, e_end, msg_id, payload)
      application_event_kinds = ApplicationEventKind.application_events_for(event_name)
      log("NOTICE EVENT: #{event_name} #{payload}", {:severity => 'info'})
      application_event_kinds.each do |aek|
        begin
          log("strating to execute_notices")
          aek.execute_notices(event_name, payload)
          log("execute_notices finished")
        rescue => e
          log("Failied to execute_notices #{e} #{e.backtrace}")
        end
      end
    end
  end
end
