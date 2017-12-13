module Subscribers
  class LawfulPresence < ::Acapi::Subscription
    include Acapi::Notifiers
    def self.subscription_details
      ["acapi.info.events.lawful_presence.vlp_verification_response"]
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
        consumer_role.lawful_presence_determination.vlp_responses << event_response_record
        if consumer_role.person.verification_types.include? "Citizenship"
          type = "Citizenship"
        elsif consumer_role.person.verification_types.include? "Immigration status"
          type = "Immigration status"
        end
        consumer_role.add_type_history_element(verification_type: type,
                                               action: "DHS Hub response",
                                               modifier: "external Hub",
                                               update_reason: "Hub response",
                                               event_response_record_id: event_response_record.id)
        if "503" == return_status
          args = OpenStruct.new
          args.determined_at = Time.now
          args.vlp_authority = 'dhs'
          consumer_role.fail_dhs!(args)
          consumer_role.save      
          return                          
        end 
        xml_hash = xml_to_hash(xml)
        update_consumer_role(consumer_role, xml_hash)
      rescue => e
        notify("acapi.error.application.enroll.remote_listener.vlp_responses", {
          :body => JSON.dump({
            :error => e.inspect,
            :message => e.message,
            :backtrace => e.backtrace
          })})
      end
    end

    def update_consumer_role(consumer_role, xml_hash)
      args = OpenStruct.new
      args.is_barred = xml_hash[:is_barred]
      if xml_hash[:is_barred].to_s == "true"
        args.bar_met = xml_hash[:bar_met]
      end
      args.five_year_bar = xml_hash[:five_year_bar]
      args.determined_at = Time.now
      args.vlp_authority = 'dhs'
      if xml_hash[:lawful_presence_indeterminate].present?
        consumer_role.fail_dhs!(args)
      elsif xml_hash[:lawful_presence_determination].present? && xml_hash[:lawful_presence_determination][:response_code].eql?("lawfully_present")
        args.citizenship_result = get_citizen_status(xml_hash[:lawful_presence_determination][:legal_status])
        consumer_role.pass_dhs!(args)
      elsif xml_hash[:lawful_presence_determination].present? && xml_hash[:lawful_presence_determination][:response_code].eql?("not_lawfully_present")
        args.citizenship_result = ::ConsumerRole::NOT_LAWFULLY_PRESENT_STATUS
        consumer_role.fail_dhs!(args)
      end
      consumer_role.save
      save_dhs_verification_responses(consumer_role)
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

    def save_dhs_verification_responses(consumer_role)
      data = Parsers::Xml::Cv::LawfulPresenceResponseParser.parse(consumer_role.lawful_presence_determination.vlp_responses.last.body)
      if data.lawful_presence_indeterminate.present?
        consumer_role.lawful_presence_determination.dhs_verification_responses << 
          DhsVerificationResponse.new(
            case_number:  data.case_number,
            response_code: data.lawful_presence_indeterminate.response_code,        
            response_text: data.lawful_presence_indeterminate.response_text
            )
      elsif data.lawful_presence_determination.present?
        consumer_role.lawful_presence_determination.dhs_verification_responses << 
          DhsVerificationResponse.new(
          case_number:  data.case_number,
          document_DS2019: data.lawful_presence_determination.document_results.document_DS2019,
          document_I20: data.lawful_presence_determination.document_results.document_I20,
          document_I327: data.lawful_presence_determination.document_results.document_I327,
          document_I551: data.lawful_presence_determination.document_results.document_I551,
          document_I571: data.lawful_presence_determination.document_results.document_I571,
          document_I766: data.lawful_presence_determination.document_results.document_I766,
          document_I94: data.lawful_presence_determination.document_results.document_I94,
          document_cert_of_citizenship: data.lawful_presence_determination.document_results.document_cert_of_citizenship,

          cert_of_naturalization_admitted_to_date: data.lawful_presence_determination.document_results.document_cert_of_naturalization.admitted_to_date,
          cert_of_naturalization_admitted_to_text: data.lawful_presence_determination.document_results.document_cert_of_naturalization.admitted_to_text,
          cert_of_naturalization_case_number: data.lawful_presence_determination.document_results.document_cert_of_naturalization.case_number,
          cert_of_naturalization_coa_code: data.lawful_presence_determination.document_results.document_cert_of_naturalization.coa_code,
          cert_of_naturalization_country_birth_code: data.lawful_presence_determination.document_results.document_cert_of_naturalization.country_birth_code,
          cert_of_naturalization_country_citizen_code: data.lawful_presence_determination.document_results.document_cert_of_naturalization.country_citizen_code,
          cert_of_naturalization_eads_expire_date: data.lawful_presence_determination.document_results.document_cert_of_naturalization.eads_expire_date,
          cert_of_naturalization_elig_statement_code: data.lawful_presence_determination.document_results.document_cert_of_naturalization.elig_statement_code,
          cert_of_naturalization_elig_statement_txt: data.lawful_presence_determination.document_results.document_cert_of_naturalization.elig_statement_txt,
          cert_of_naturalization_entry_date: data.lawful_presence_determination.document_results.document_cert_of_naturalization.entry_date,
          cert_of_naturalization_grant_date: data.lawful_presence_determination.document_results.document_cert_of_naturalization.grant_date,
          cert_of_naturalization_grant_date_reason_code: data.lawful_presence_determination.document_results.document_cert_of_naturalization.grant_date_reason_code,
          cert_of_naturalization_iav_type_code: data.lawful_presence_determination.document_results.document_cert_of_naturalization.iav_type_code,
          cert_of_naturalization_iav_type_text: data.lawful_presence_determination.document_results.document_cert_of_naturalization.iav_type_text,
          cert_of_naturalization_response_code: data.lawful_presence_determination.document_results.document_cert_of_naturalization.response_code,
          cert_of_naturalization_response_description_text: data.lawful_presence_determination.document_results.document_cert_of_naturalization.response_description_text,
          cert_of_naturalization_tds_response_description_text: data.lawful_presence_determination.document_results.document_cert_of_naturalization.tds_response_description_text,

          passport_admitted_to_date: data.lawful_presence_determination.document_results.document_foreign_passport.admitted_to_date,
          passport_admitted_to_text: data.lawful_presence_determination.document_results.document_foreign_passport.admitted_to_text,
          passport_case_number: data.lawful_presence_determination.document_results.document_foreign_passport.case_number,
          passport_coa_code: data.lawful_presence_determination.document_results.document_foreign_passport.coa_code,
          passport_country_birth_code: data.lawful_presence_determination.document_results.document_foreign_passport.country_birth_code,
          passport_country_citizen_code: data.lawful_presence_determination.document_results.document_foreign_passport.country_citizen_code,
          passport_eads_expire_date: data.lawful_presence_determination.document_results.document_foreign_passport.eads_expire_date,
          passport_elig_statement_code: data.lawful_presence_determination.document_results.document_foreign_passport.elig_statement_code,
          passport_elig_statement_txt: data.lawful_presence_determination.document_results.document_foreign_passport.elig_statement_txt,
          passport_entry_date: data.lawful_presence_determination.document_results.document_foreign_passport.entry_date,
          passport_grant_date: data.lawful_presence_determination.document_results.document_foreign_passport.grant_date,
          passport_grant_date_reason_code: data.lawful_presence_determination.document_results.document_foreign_passport.grant_date_reason_code,
          passport_iav_type_code: data.lawful_presence_determination.document_results.document_foreign_passport.iav_type_code,

          passport_iav_type_text: data.lawful_presence_determination.document_results.document_foreign_passport.iav_type_text,
          passport_response_code: data.lawful_presence_determination.document_results.document_foreign_passport.response_code,
          passport_response_description_text: data.lawful_presence_determination.document_results.document_foreign_passport.response_description_text,
          passport_tds_response_description_text: data.lawful_presence_determination.document_results.document_foreign_passport.tds_response_description_text,
          document_foreign_passport_I94: data.lawful_presence_determination.document_results.document_foreign_passport_I94,
          document_mac_read_I551: data.lawful_presence_determination.document_results.document_mac_read_I551,
          document_other_case_1: data.lawful_presence_determination.document_results.document_other_case_1,
          document_other_case_2: data.lawful_presence_determination.document_results.document_other_case_2,
          document_temp_I551: data.lawful_presence_determination.document_results.document_temp_I551,
          employment_authorized: data.lawful_presence_determination.employment_authorized,
          legal_status: data.lawful_presence_determination.legal_status,
          response_code: data.lawful_presence_determination.response_code,
          lawful_presence_indeterminate: data.lawful_presence_indeterminate
        )
      end
    end
  end
end
