module Subscribers
  class FamilyApplicationCompleted < ::Acapi::Subscription
    def self.subscription_details
        ["acapi.info.events.family.application_completed"]
    end

    def call(event_name, e_start, e_end, msg_id, payload)
      stringed_key_payload = payload.stringify_keys
      xml = stringed_key_payload["body"]
      #parser = Parsers::Xml::Cv::VerifiedFamilyParser.new
      # parser.parse(xml)
      # parser.to_hash #gives you hash of this payload
    end
  end
end
