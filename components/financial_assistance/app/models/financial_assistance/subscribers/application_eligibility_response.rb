# frozen_string_literal: true

module FinancialAssistance
  module Subscribers
    class ApplicationEligibilityResponse < ::Acapi::Subscription
      include Acapi::Notifiers

      ELIGIBILITY_SCHEMA_FILE_PATH = File.join(FinancialAssistance::Engine.root, 'lib', 'schemas', 'financial_assistance.xsd')

      def self.subscription_details
        ['acapi.info.events.assistance_application.application_processed']
      end

      def call(_event_name, _e_start, _e_end, _msg_id, payload)
        stringed_key_payload = payload.stringify_keys
        xml = stringed_key_payload['body']
        application = FinancialAssistance::Application.where(:hbx_id => stringed_key_payload['assistance_application_id']).first if stringed_key_payload['assistance_application_id'].present?

        if application.present?
          payload_http_status_code = stringed_key_payload['return_status']

          if application.success_status_codes?(payload_http_status_code.to_i)
            if eligibility_payload_schema_valid?(xml)
              application.add_eligibility_determination(determination_http_status_code: payload_http_status_code, has_eligibility_response: true, haven_app_id: stringed_key_payload['haven_application_id'], haven_ic_id: stringed_key_payload['haven_ic_id'], eligibility_response_payload: xml)
            else
              application.set_determination_response_error!
              application.update_attributes(determination_http_status_code: 422, has_eligibility_response: true, determination_error_message: 'Failed to validate Eligibility Determination response XML')
              log(xml, {:severity => 'critical', :error_message => 'ERROR: Failed to validate Eligibility Determination response XML'})
            end
          else
            error_message = stringed_key_payload['body']
            application.set_determination_response_error!
            application.update_attributes(determination_http_status_code: payload_http_status_code, has_eligibility_response: true, determination_error_message: error_message)
          end
        else
          log(xml, {:severity => 'critical', :error_message => 'ERROR: Failed to find the Application in XML'})
        end
      end

      def eligibility_payload_schema_valid?(xml)
        return false if xml.blank?
        xml = Nokogiri::XML.parse(xml)
        xsd = Nokogiri::XML::Schema(File.open(ELIGIBILITY_SCHEMA_FILE_PATH))
        xsd.valid?(xml)
      end

      # def haven_import_from_xml(xml)
      #   verified_family = Parsers::Xml::Cv::HavenVerifiedFamilyParser.new
      #   verified_family.parse(xml)
      #   verified_primary_family_member = verified_family.family_members.detect {|fm| fm.person.hbx_id == verified_family.primary_family_member_id}
      #   verified_dependents = verified_family.family_members.reject {|fm| fm.person.hbx_id == verified_family.primary_family_member_id}
      #   application_in_context = FinancialAssistance::Application.where(:hbx_id => verified_family.fin_app_id).first
      #
      #
      #   primary_person = search_person(verified_primary_family_member)
      #
      #   if primary_person.blank?
      #     application_in_context.set_determination_response_error!
      #     application_in_context.update_attributes(determination_http_status_code: 422, has_eligibility_response: true, determination_error_message: 'Failed to find primary person in xml')
      #     throw(:processing_issue, 'ERROR: Failed to find primary person in xml')
      #   end
      #
      #   family = primary_person.primary_family
      #
      #   if family.blank?
      #     application_in_context.set_determination_response_error!
      #     application_in_context.update_attributes(determination_http_status_code: 422, has_eligibility_response: true, determination_error_message: 'Failed to find primary family for users person in xml')
      #     throw(:processing_issue, 'ERROR: Failed to find primary family for users person in xml')
      #   end
      #
      #   active_household = family.active_household
      #   family.save!
      #   active_verified_household = verified_family.households.max_by(&:start_date)
      #
      #   verified_dependents.each do |verified_family_member|
      #     next unless search_person(verified_family_member).blank?
      #     application_in_context.set_determination_response_error!
      #     application_in_context.update_attributes(determination_http_status_code: 422, has_eligibility_response: true, determination_error_message: 'Failed to find dependent from xml')
      #     throw(:processing_issue, 'ERROR: Failed to find dependent from xml')
      #   end
      #
      #   primary_person = search_person(verified_primary_family_member) #such mongoid
      #   family.save!
      #   family.e_case_id = verified_family.integrated_case_id
      #
      #   begin
      #     active_household.build_or_update_tax_households_and_applicants_and_eligibility_determinations(verified_family, primary_person, active_verified_household, application_in_context)
      #   rescue StandardError
      #     application_in_context.set_determination_response_error!
      #     application_in_context.update_attributes(determination_http_status_code: 422, determination_error_message: 'Failure to update tax household')
      #     throw(:processing_issue, 'ERROR: Failure to update tax household')
      #   end
      #
      #   begin
      #     family.save!
      #     application_in_context.determine!
      #   rescue StandardError
      #     throw(:processing_issue, 'ERROR: Failure to save family or to transition application to determined state')
      #   end
      # end
      #
      # def search_person(verified_family_member)
      #   ssn = verified_family_member.person_demographics.ssn
      #   ssn = '' if ssn == '999999999'
      #   dob = verified_family_member.person_demographics.birth_date
      #   last_name_regex = /^#{verified_family_member.person.name_last}$/i
      #   first_name_regex = /^#{verified_family_member.person.name_first}$/i
      #
      #   if !ssn.blank?
      #     Person.where({
      #                    :encrypted_ssn => Person.encrypt_ssn(ssn),
      #                    :dob => dob
      #                  }).first
      #   else
      #     Person.where({
      #                    :dob => dob,
      #                    :last_name => last_name_regex,
      #                    :first_name => first_name_regex
      #                  }).first
      #   end
      # end
    end
  end
end
