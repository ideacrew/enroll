module Subscribers
  class FamilyApplicationCompleted < ::Acapi::Subscription
    def self.subscription_details
        ["acapi.info.events.family.application_completed"]
    end

    def call(event_name, e_start, e_end, msg_id, payload)
      stringed_key_payload = payload.stringify_keys
      xml = stringed_key_payload["body"]
    end
  end
end
