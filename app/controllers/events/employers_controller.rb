module Events
  class EmployersController < ::ApplicationController
    include Acapi::Notifiers

    def self.binder_paid_subscription_details
      EmployerProfile::BINDER_PREMIUM_PAID_EVENT_NAME
    end

    def self.updated_subscription_details
      EmployerProfile::EMPLOYER_PROFILE_UPDATED_EVENT_NAME
    end

    def updated(e_start, e_end, msg_id, payload)
      employer = payload.stringify_keys["employer"]
      event_payload = render_to_string "updated", :formats => ["xml"], :locals => { :employer => employer }

      notify("acapi.info.events.employer.updated", {:body => event_payload})
    end

    def binder_paid(e_start, e_end, msg_id, payload)
      employer = payload.stringify_keys["employer"]
      event_payload = render_to_string "updated", :formats => ["xml"], :locals => { :employer => employer }

      notify("acapi.info.events.employer.binder_premium_paid", {:body => event_payload})
    end

    def self.subscribe
      ActiveSupport::Notifications.subscribe(self.binder_paid_subscription_details) do |e_name, e_start, e_end, msg_id, payload|
        self.new.binder_paid(e_start,e_end,msg_id,payload)
      end
      ActiveSupport::Notifications.subscribe(self.updated_subscription_details) do |e_name, e_start, e_end, msg_id, payload|
        self.new.updated(e_start,e_end,msg_id,payload)
      end
    end
  end
end
