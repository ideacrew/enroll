module Notifier
  class NotificationSubscriber < ::Acapi::Subscription
    include Acapi::Notifiers

    def self.subscription_details
      [/acapi\.info\.events\..*/]
    end

    def call(event_name, e_start, e_end, msg_id, payload)
      log("NOTICE EVENT: #{event_name} #{payload}", {:severity => 'info'})

      NoticeKind.where(event_name: event_name.split(".")[4]).each do |notice_kind|
        begin          
          notice_kind.execute_notice(event_name, payload)
        rescue Exception => e
          # ADD LOGGING AND HANDLING
          puts "#{e.inspect} #{e.backtrace}"
        end
      end
    end
  end
end