module Events
  class ResidencyVerificationRequestsController < ::ApplicationController
    include Acapi::Notifiers

    def self.subscription_details
      [ConsumerRole::RESIDENCY_VERIFICATION_REQUEST_EVENT_NAME]
    end

    def call(event_name, e_start, e_end, msg_id, payload)
      individual = payload.stringify_keys["person"]
      event_payload = render_to_string "events/residency/verification_request", :formats => ["xml"], :locals => { :individual => individual }

      notify("acapi.info.events.residency.verification_request", {:body => event_payload, :individual_id => individual.hbx_id, :retry_deadline => (Time.now + 24.hours).to_i})
    end

    def self.subscribe
      ActiveSupport::Notifications.subscribe(*self.subscription_details) do |e_name, e_start, e_end, msg_id, payload|
        self.new.call(e_name, e_start,e_end,msg_id,payload)
      end
    end
  end
end
