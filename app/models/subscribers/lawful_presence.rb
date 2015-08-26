module Subscribers
  class LawfulPresence < ::Acapi::Subscription
    def self.subscription_details
      ["local.enroll.lawful_presence.lawful_presence_response"]
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
      consumer_role.raw_event_responses << {:lawful_presence_response => payload}
      xml_hash = xml_to_hash(xml)

      update_consumer_role(consumer_role, xml_hash)
    end

    def update_consumer_role(consumer_role, xml_hash)
      args = OpenStruct.new

      if xml_hash[:lawful_presence_indeterminate].present?
        args.determined_at = Time.now
        args.vlp_authority = 'ssa'
        consumer_role.deny_lawful_presence(args)
      elsif xml_hash[:lawful_presence_determination].present?
        args.determined_at = Time.now
        args.vlp_authority = 'ssa'
        args.citizen_status = get_citizen_status(xml_hash[:lawful_presence_determination][:legal_status])
        consumer_role.authorize_lawful_presence(args)
      end

      consumer_role.save
    end

    def get_citizen_status(legal_status)
      return "us_citizen" if legal_status.eql? "citizen"
      return "lawful_permanent_resident" if legal_status.eql? "lawful_permanent_resident"
      return "alien_lawfully_present" if ["asylee", "refugee", "non_immigrant", "application_pending", "student", "asylum_application_pending", "daca" ].include? legal_status
    end

    def xml_to_hash(xml)
      Parsers::Xml::Cv::LawfulPresenceResponseParser.parse(xml).to_hash
    end

    def find_person(person_hbx_id)
      Person.where(hbx_id:person_hbx_id).first
    end
  end
end