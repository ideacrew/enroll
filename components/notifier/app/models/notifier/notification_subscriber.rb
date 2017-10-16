module Notifier
  class NotificationSubscriber < ::Acapi::Subscription
    include Acapi::Notifiers

    def self.subscription_details
      [/acapi\.info\.events\..*/]
    end

    def call(event_name, e_start, e_end, msg_id, payload)
      notice_kinds = notice_kind_for(event_name)
      log("NOTICE EVENT: #{event_name} #{payload}", {:severity => 'info'})

      notice_kinds.each do |aek|
        begin
          aek.execute_notices(event_name, payload)
        rescue Exception => e
          # ADD LOGGING AND HANDLING
          puts "#{e.inspect} #{e.backtrace}"
        end
      end
    end

    def self.notice_kind_for(event_name)
      resource_name, event_name = extract_event_parts(event_name)
      NoticeKind.where(event_name: event_name, resource_name: resource_name)
    end

    def extract_event_parts(event_name)
      event_parts = event_name.split(".")
      [event_parts[3], event_parts[4]]
    end
  end
end
