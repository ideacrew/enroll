module Subscribers
  class FinancialAssistanceApplicationOutstandingVerification < ::Acapi::Subscription
    include Acapi::Notifiers

    VERIFICATION_SCHEMA_FILE_PATH = File.join(Rails.root, 'lib', 'schemas', 'verification_services.xsd')

    def self.subscription_details
      ["acapi.info.events.outstanding_verification.submitted"]
    end

    def call(event_name, e_start, e_end, msg_id, payload)
      stringed_key_payload = payload.stringify_keys
      xml = stringed_key_payload["body"]

      application = FinancialAssistance::Application.find(stringed_key_payload["assistance_application_id"]) if stringed_key_payload["assistance_application_id"].present?
      if application.present? && application.aasm_state == "determined"
        if verification_payload_schema_valid?(xml)
          sc = ShortCircuit.on(:processing_issue) do |err|
            log(xml, {:severity => "critical", :error_message => err})
          end
          sc.and_then do |payload|
            haven_verifications_import_from_xml(payload)
          end
          sc.call(xml)
        else
          message = "Invalid schema eligibility determination response provided"
          notify("acapi.info.events.verification.rejected",
                    {:correlation_id => SecureRandom.uuid.gsub("-",""),
                      :body => JSON.dump({error: message,
                                          applicant_first_name: applicant.person.first_name,
                                          applicant_last_name: applicant.person.last_name,
                                          applicant_id: applicant.person.hbx_id}),
                      :assistance_application_id => stringed_key_payload["assistance_application_id"],
                      :family_id => stringed_key_payload["family_id"],
                      :primary_applicant_id => stringed_key_payload["primary_applicant_id"],
                      :haven_application_id => stringed_key_payload["haven_application_id"],
                      :haven_ic_id => stringed_key_payload["haven_ic_id"],
                      :reject_status => 422,
                      :submitted_timestamp => TimeKeeper.date_of_record.strftime('%Y-%m-%dT%H:%M:%S')})

          log(xml, {:severity => "critical", :error_message => "ERROR: Failed to validate Verification response XML"})
        end
      else
        log(xml, {:severity => "critical", :error_message => "ERROR: Failed to find the Application or Determined Application in XML"})
      end
    end

    def haven_verifications_import_from_xml(xml)
      if xml.include?('income_verification_result')
        verified_income_verification = Parsers::Xml::Cv::OutstandingIncomeVerificationParser.new
        verified_income_verification.parse(xml)
        verified_person = verified_income_verification.verifications.first.individual

        person_in_context = search_person(verified_person)
        throw(:processing_issue, "ERROR: Failed to find primary person in xml") unless person_in_context.present?

        applicant_in_context = FinancialAssistance::Application.find(verified_income_verification.fin_app_id).applicants.select { |applicant| applicant.person.hbx_id == person_in_context.hbx_id}.first
        throw(:processing_issue, "ERROR: Failed to find applicant in xml") unless applicant_in_context.present?
        applicant_in_context.update_attributes(has_income_verification_response: true)

        income_assisted_verification = applicant_in_context.assisted_verifications.where(verification_type: "Income").first
        if income_assisted_verification.present?
          if income_assisted_verification.status == "pending"
            income_assisted_verification.update_attributes(status: verified_income_verification.verifications.first.response_code.split('#').last, verification_failed: verified_income_verification.verifications.first.income_verification_failed)
          else
            new_income_assisted_verification = applicant_in_context.assisted_verifications.create!(verification_type: "Income", status: verified_income_verification.verifications.first.response_code.split('#').last, verification_failed: verified_income_verification.verifications.first.income_verification_failed)
            applicant_in_context.person.consumer_role.assisted_verification_documents.create(application_id: verified_income_verification.fin_app_id, applicant_id: applicant_in_context.id, assisted_verification_id: new_income_assisted_verification.id, status: new_income_assisted_verification.status, kind: new_income_assisted_verification.verification_type)
          end
        else
          throw(:processing_issue, "ERROR: Failed to find Income verification for the applicant") unless person_in_context.present?
        end
      elsif xml.include?('mec_verification_result')
        verified_mec_verfication = Parsers::Xml::Cv::OutstandingMecVerificationParser.new
        verified_mec_verfication.parse(xml)
        verified_person = verified_mec_verfication.verifications.first.individual

        person_in_context = search_person(verified_person)
        throw(:processing_issue, "ERROR: Failed to find primary person in xml") unless person_in_context.present?

        applicant_in_context = FinancialAssistance::Application.find(verified_mec_verfication.fin_app_id).applicants.select { |applicant| applicant.person.hbx_id == person_in_context.hbx_id}.first
        throw(:processing_issue, "ERROR: Failed to find applicant in xml") unless applicant_in_context.present?
        applicant_in_context.update_attributes(has_mec_verification_response: true)

        mec_assisted_verification = applicant_in_context.assisted_verifications.where(verification_type: "MEC").first
        if mec_assisted_verification.present?
          if mec_assisted_verification.status == "pending"
            mec_assisted_verification.update_attributes(status: verified_mec_verfication.verifications.first.response_code.split('#').last, verification_failed: verified_mec_verfication.verifications.first.mec_verification_failed)
          else
            new_mec_assisted_verification = applicant_in_context.assisted_verifications.create!(verification_type: "MEC", status: verified_mec_verfication.verifications.first.response_code.split('#').last, verification_failed: verified_mec_verfication.verifications.first.mec_verification_failed)
            applicant_in_context.person.consumer_role.assisted_verification_documents.create(application_id: verified_mec_verfication.fin_app_id, applicant_id: applicant_in_context.id, assisted_verification_id: new_mec_assisted_verification.id, status: new_mec_assisted_verification.status, kind: new_mec_assisted_verification.verification_type)
          end
        else
          throw(:processing_issue, "ERROR: Failed to find MEC verification for the applicant") unless person_in_context.present?
        end
      else
        log(xml, {:severity => "critical", :error_message => "ERROR: Failed to find the Income/MEC verification in XML"})
      end
    end

    def search_person(verified_person)
      ssn = verified_person.person_demographics.ssn
      ssn = '' if ssn == "999999999"
      dob = verified_person.person_demographics.birth_date
      last_name_regex = /^#{verified_person.person.name_last}$/i
      first_name_regex = /^#{verified_person.person.name_first}$/i

      if !ssn.blank?
        Person.where({
          :encrypted_ssn => Person.encrypt_ssn(ssn),
          :dob => dob
        }).first
      else
        Person.where({
          :dob => dob,
          :last_name => last_name_regex,
          :first_name => first_name_regex
        }).first
      end
    end

    def verification_payload_schema_valid?(xml)
      return false if xml.blank?
      xml = Nokogiri::XML.parse(xml)
      xsd = Nokogiri::XML::Schema(File.open VERIFICATION_SCHEMA_FILE_PATH)
      xsd.valid?(xml)
    end
  end
end