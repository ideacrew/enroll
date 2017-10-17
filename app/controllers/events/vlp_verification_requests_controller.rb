module Events
  class VlpVerificationRequestsController < ::ApplicationController
    include Acapi::Notifiers

    def self.subscription_details
      [LawfulPresenceDetermination::VLP_VERIFICATION_REQUEST_EVENT_NAME]
    end

    def call(event_name, e_start, e_end, msg_id, payload)
      individual = payload.stringify_keys["person"]
      coverage_start_date = payload.stringify_keys["coverage_start_date"]
      event_payload = render_to_string "events/lawful_presence/vlp_verification_request", :formats => ["xml"], :locals => { :individual => individual, :coverage_start_date => coverage_start_date }
      individual.consumer_role.lawful_presence_determination.vlp_requests << EventRequest.new({requested_at: Time.now, body: event_payload})

      notify("acapi.info.events.lawful_presence.vlp_verification_request", {:body => event_payload, :individual_id => individual.hbx_id, :retry_deadline => (Time.now + 24.hours).to_i})
    end

    def self.subscribe
      ActiveSupport::Notifications.subscribe(*self.subscription_details) do |e_name, e_start, e_end, msg_id, payload|
        self.new.call(e_name, e_start,e_end,msg_id,payload)
      end
    end
  end
end
