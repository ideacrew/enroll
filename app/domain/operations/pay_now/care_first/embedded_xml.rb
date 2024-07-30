# frozen_string_literal: true

require "dry/monads"
require "dry/monads/do"
require "aca_entities/pay_now/care_first/operations/generate_xml"

module Operations
  module PayNow
    module CareFirst
      # Generate Pay Now custom embedded XML payload for CareFirst carrier
      class EmbeddedXml
        include Dry::Monads[:do, :result]

        def call(enrollment)
          cv3_enrollment = yield transform_enrollment(enrollment)
          cv3_members = yield transform_member_array(enrollment)
          payload = yield construct_payload(cv3_enrollment, cv3_members)
          xml_response = yield transform_xml(payload)
          cleaned_xml = yield clean_xml(xml_response)
          Success(cleaned_xml)
        end

        private

        def transform_enrollment(enrollment)
          cv3_enrollment = Operations::Transformers::HbxEnrollmentTo::Cv3HbxEnrollment.new.call(enrollment)
          cv3_enrollment.success? ? cv3_enrollment : Failure("unable to transform hbx enrollment #{enrollment.hbx_id} due to #{cv3_enrollment.failure}")
        end

        def transform_member_array(enrollment)
          error_message = ""
          cv3_members = enrollment.hbx_enrollment_members.inject([]) do |members, hem|
            person = hem.person
            cv3_person = Operations::Transformers::PersonTo::Cv3Person.new.call(person)
            next members << cv3_person.value! if cv3_person.success?
            error_message.concat("Unable to transform person #{person.hbx_id} due to #{cv3_person.failure}. ")
          end
          error_message.empty? ? Success(cv3_members) : Failure(error_message)
        end

        def construct_payload(cv3_enrollment, cv3_members)
          payload = {
            coverage_and_members: {
              hbx_enrollment: cv3_enrollment,
              members: cv3_members
            }
          }
          Success(payload)
        end

        def transform_xml(payload)
          xml_response = ::AcaEntities::PayNow::CareFirst::Operations::GenerateXml.new.call(payload)
          xml_response.success? ? xml_response : Failure("unable to create xml due to #{xml_response.failure}.")
        end

        def clean_xml(xml)
          # clean xml of whitespace around tags
          cleaned_xml = xml.gsub(/>\s+</, '><').strip
          Success(cleaned_xml)
        rescue StandardError => e
          Failure("::Operations::PayNow::CareFirst::EmbeddedXml.clean_xml -> #{e}")
        end
      end
    end
  end
end
