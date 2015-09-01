module Subscribers
  class LocalResidency < ::Acapi::Subscription
    def self.subscription_details
      ["acapi.info.events.residency.verification_response"]
    end

    def call(event_name, e_start, e_end, msg_id, payload)
      process_response(payload)
    end

    private
    def process_response(payload)
      stringed_key_payload = payload.stringify_keys
      xml = stringed_key_payload['body']
      person_hbx_id = stringed_key_payload['individual_id']

      person = find_person(person_hbx_id)
      return if person.nil? || person.consumer_role.nil?

      consumer_role = person.consumer_role
      consumer_role.local_residency_responses << EventResponse.new({received_at: Time.now, body: xml})

      xml_hash = xml_to_hash(xml)

      update_consumer_role(consumer_role, xml_hash)
    end

    def update_consumer_role(consumer_role, xml_hash)
      if xml_hash[:residency_verification_response].eql? 'ADDRESS_NOT_IN_AREA'
        consumer_role.deny_residency!
      else
        consumer_role.authorize_residency!
      end

      consumer_role.save
    end

    def xml_to_hash(xml)
      Parsers::Xml::Cv::ResidencyVerificationResponse.parse(xml).to_hash
    end

    def find_person(person_hbx_id)
      Person.where(hbx_id:person_hbx_id).first
    end
  end
end
