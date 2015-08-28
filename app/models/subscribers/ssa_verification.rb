module Subscribers
  class SsaVerification < ::Acapi::Subscription
    def self.subscription_details
      ["local.enroll.lawful_presence.ssa_verification_response"]
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
      consumer_role.lawful_presence_determination.ssa_verifcation_responses.build({received_at: Time.now, body: payload}).save

      xml_hash = xml_to_hash(xml)

      update_consumer_role(consumer_role, xml_hash)
    end

    def update_consumer_role(consumer_role, xml_hash)
      args = OpenStruct.new

      if xml_hash[:ssn_verification_failed].eql?("true")
        args.determined_at = Time.now
        args.vlp_authority = 'ssa'
        consumer_role.deny_lawful_presence(args)
      elsif xml_hash[:ssn_verified].eql?("true") && xml_hash[:citizenship_verified].eql?("true")
        args.determined_at = Time.now
        args.vlp_authority = 'ssa'
        args.citizen_status = ::ConsumerRole::US_CITIZEN_STATUS
        consumer_role.authorize_lawful_presence(args)
      end

      consumer_role.save
    end

    def xml_to_hash(xml)
      Parsers::Xml::Cv::SsaVerificationResultParser.parse(xml).to_hash
    end

    def find_person(person_hbx_id)
      Person.where(hbx_id:person_hbx_id).first
    end
  end
end