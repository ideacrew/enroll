module Subscribers
  class SsaVerification < ::Acapi::Subscription
    include Acapi::Notifiers

    def self.subscription_details
      ["acapi.info.events.lawful_presence.ssa_verification_response"]
    end

    def call(event_name, e_start, e_end, msg_id, payload)
      process_response(payload)
    end

    private
    def process_response(payload)
      begin
        stringed_key_payload = payload.stringify_keys
        xml = stringed_key_payload['body']
        person_hbx_id = stringed_key_payload['individual_id']
        return_status = stringed_key_payload["return_status"].to_s

        person = find_person(person_hbx_id)
        return if person.nil? || person.consumer_role.nil?

        consumer_role = person.consumer_role
        event_response_record = EventResponse.new({received_at: Time.now, body: xml})
        consumer_role.lawful_presence_determination.ssa_responses << event_response_record
        person.verification_types.active.reject{|type| ["DC Residency", "American Indian Status", "Immigration status"].include? type.type_name}.each do |type|
          type.add_type_history_element(action: "SSA Hub Response",
                                        modifier: "external Hub",
                                        update_reason: "Hub response",
                                        event_response_record_id: event_response_record.id)
        end

        #TODO change response handler
        if "503" == return_status.to_s
          args = OpenStruct.new
          args.determined_at = Time.now
          args.vlp_authority = 'ssa'
          consumer_role.ssn_invalid!(args)
          consumer_role.save
          return
        end

        xml_hash = xml_to_hash(xml)
        update_consumer_role(consumer_role, xml_hash)
      rescue => e
        notify("acapi.error.application.enroll.remote_listener.ssa_responses", {
          :body => JSON.dump({
             :error => e.inspect,
             :message => e.message,
             :backtrace => e.backtrace
          })})
      end
    end

    def update_consumer_role(consumer_role, xml_hash)
      args = OpenStruct.new

      if xml_hash[:ssn_verification_failed].eql?("true")
        args.determined_at = Time.now
        args.vlp_authority = 'ssa'
        consumer_role.ssn_invalid!(args)
      elsif xml_hash[:ssn_verified].eql?("true") && xml_hash[:citizenship_verified].eql?("true")
        args.determined_at = Time.now
        args.vlp_authority = 'ssa'
        args.citizenship_result = ::ConsumerRole::US_CITIZEN_STATUS
        consumer_role.ssn_valid_citizenship_valid!(args)
      elsif xml_hash[:ssn_verified].eql?("true") && xml_hash[:citizenship_verified].eql?("false")
        args.determined_at = Time.now
        args.vlp_authority = 'ssa'
        args.citizenship_result = ::ConsumerRole::NOT_LAWFULLY_PRESENT_STATUS
        consumer_role.ssn_valid_citizenship_invalid!(args)
      end
      consumer_role.save
      save_ssa_verification_responses(consumer_role)
    end

    def xml_to_hash(xml)
      Parsers::Xml::Cv::SsaVerificationResultParser.parse(xml).to_hash
    end

    def find_person(person_hbx_id)
      Person.where(hbx_id:person_hbx_id).first
    end

    def save_ssa_verification_responses(consumer_role)
      data = Parsers::Xml::Cv::SsaVerificationResultParser.parse(consumer_role.lawful_presence_determination.ssa_responses.last.body)
      consumer_role.lawful_presence_determination.ssa_verification_responses <<
      SsaVerificationResponse.new(
        response_code: data.response_code,
        response_text: data.response_text,
        ssn_verification_failed: data.ssn_verification_failed,
        death_confirmation: data.death_confirmation,
        ssn_verified: data.ssn_verified,
        citizenship_verified: data.citizenship_verified,
        incarcerated: data.incarcerated,
        ssn: data.individual.person_demographics.ssn,
        sex: data.individual.person_demographics.sex,
        birth_date: data.individual.person_demographics.birth_date,
        is_state_resident: data.individual.person_demographics.is_state_resident,
        citizen_status: data.individual.person_demographics.citizen_status,
        marital_status: data.individual.person_demographics.marital_status,
        death_date: data.individual.person_demographics.death_date,
        race: data.individual.person_demographics.race,
        ethnicity: data.individual.person_demographics.ethnicity,
        person_id: data.individual.person.id,
        first_name: data.individual.person.name_first,
        last_name: data.individual.person.name_last,
        name_pfx: data.individual.person.name_pfx,
        name_sfx: data.individual.person.name_sfx,
        middle_name: data.individual.person.name_middle,
        full_name: data.individual.person.name_full

        )
        data.individual.person.addresses.each do |address|
         consumer_role.lawful_presence_determination.ssa_verification_responses.last.individual_address << Address.new({kind: address.type, address_1:  address.address_line_1, address_2:  address.address_line_2, city:  address.location_city_name,
                           state:  address.location_state, zip:  address.location_postal_code, location_state_code: address.location_state_code,
                           full_text: address.address_full_text, country_name: address.location_country_name })
        end
        data.individual.person.emails.each do |email|
         consumer_role.lawful_presence_determination.ssa_verification_responses.last.individual_email << Email.new(kind: email.type, address:  email.email_address)
        end
        data.individual.person.phones.each do |phone|
         consumer_role.lawful_presence_determination.ssa_verification_responses.last.individual_phone << Phone.new(kind: phone.type,country_code: phone.country_code,area_code: phone.area_code,
                            number: phone.phone_number,extension: phone.extension,primary: phone.is_preferred,full_phone_number: phone.full_phone_number)
        end

    end
  end
end
