module Events
  class EmployersController < ::ApplicationController
    include Acapi::Notifiers

    def self.subscription_details
      [EmployerProfile::BINDER_PREMIUM_PAID_EVENT_NAME]
    end

    def call(event_name, e_start, e_end, msg_id, payload)
      e_type = event_name.split(".").last
      employer = payload.stringify_keys["employer"]
      event_payload = render_to_string "updated", :formats => ["xml"], :locals => { :employer => employer }

      notify("acapi.info.events.employer.#{e_type}", {:body => event_payload})
    end

    def self.subscribe
      ActiveSupport::Notifications.subscribe(*self.subscription_details) do |e_name, e_start, e_end, msg_id, payload|
        self.new.call(e_name, e_start,e_end,msg_id,payload)
      end
    end
  end
end
