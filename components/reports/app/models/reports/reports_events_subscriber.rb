module Reports
  class ReportsEventsSubscriber < ::Acapi::Subscription
    include Acapi::Notifiers

    def self.subscription_details
      [/acapi\.info\.events\..*/]
    end

    def call(event_name, e_start, e_end, msg_id, payload)
      log("NOTICE EVENT: #{event_name} #{payload}", {:severity => 'info'})

      begin
        event_name = event_name.split(".")[4]
        if event_name.to_sym == :federal_irs_h36
          # Trigger H36
        end
      rescue Exception => e
        # ADD LOGGING AND HANDLING
        puts "#{e.inspect} #{e.backtrace}"
        error_payload = JSON.dump({
          :error => e.inspect,
          :message => e.message,
          :backtrace => e.backtrace
          })
        notify("acapi.error.application.enroll.remote_listener.notice_automation_responses", {
          :resource_id => payload.first[1],
          :event_name => event_name,
          :return_status => "500",
          :body => error_payload
          })
      end
    end
  end
end