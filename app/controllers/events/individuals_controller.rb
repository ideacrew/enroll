module Events
  class IndividualsController < ::ApplicationController
    include Acapi::Notifiers

    def self.created_subscription_details
      Person::PERSON_CREATED_EVENT_NAME
    end

    def self.created_subscription_details
      Person::PERSON_UPDATED_EVENT_NAME
    end

    def created(e_start, e_end, msg_id, payload)
      individual = payload.stringify_keys["individual"]
      event_payload = render_to_string "created", :formats => ["xml"], :locals => { :individual => individual }

      notify("acapi.info.events.individual.created", {:body => event_payload})
    end

    def updated(e_start, e_end, msg_id, payload)
      individual = payload.stringify_keys["individual"]
      event_payload = render_to_string "created", :formats => ["xml"], :locals => { :individual => individual }

      notify("acapi.info.events.individual.updated", {:body => event_payload})
    end

    def self.subscribe
      ActiveSupport::Notifications.subscribe(self.created_subscription_details) do |e_name, e_start, e_end, msg_id, payload|
        self.new.created(e_start,e_end,msg_id,payload)
      end
      ActiveSupport::Notifications.subscribe(self.updated_subscription_details) do |e_name, e_start, e_end, msg_id, payload|
        self.new.updated(e_start,e_end,msg_id,payload)
      end
    end
  end
end
