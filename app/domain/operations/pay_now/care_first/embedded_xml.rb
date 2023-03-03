# frozen_string_literal: true

require "dry/monads"
require "dry/monads/do"

module Operations
  module PayNow
    module CareFirst
      # Generate Pay Now custom embedded XML payload for CareFirst carrier
      class EmbeddedXml
        include Dry::Monads[:result, :do]

        def call(enrollment)
          cv3_enrollment = yield transform_enrollment(enrollment)
          cv3_members = yield transform_member_array(enrollment)
          payload = yield construct_payload(cv3_enrollment, cv3_members)
          xml_response = yield transform_xml(payload)
          Success(xml_response)
        end

        private

        def transform_enrollment(enrollment)
          cv3_enrollment = Operations::Transformers::HbxEnrollmentTo::Cv3HbxEnrollment.new.call(enrollment)
          cv3_enrollment.success? ? cv3_enrollment : Failure("unable to transform hbx enrollment #{hbx_enrollment.hbx_id} due to #{cv3_enrollment.failure}")
        end

        def transform_member_array(enrollment)
          members = []
          enrollment.hbx_enrollment_members.each do |hem|
            person = hem.person
            cv3_person = Operations::Transformers::PersonTo::Cv3Person.new.call(person)
            return Failure("unable to transform person #{person.hbx_id} due to #{cv3_person.failure}") unless cv3_person.success?
            members << cv3_person.value!
          end
          Success(members)
        end

        def construct_payload(cv3_enrollment, cv3_members)
          payload = {
            hbx_enrollment: cv3_enrollment,
            members: cv3_members
          }
          Success(payload)
        end

        def transform_xml(payload)
          #call aca entities
          xml_response = Success(payload) # this will change once we have aca entities piece
          xml_response.success? ? xml_response : Failure("unable to create xml")
        end
      end
    end
  end
end
