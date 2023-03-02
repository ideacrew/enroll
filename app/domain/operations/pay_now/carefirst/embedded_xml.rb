module Operations
  module PayNow
    module Carefirst
      module EmbeddedXml
        # format will be {members: [array of cv3 person payloads], enrollment: cv3 enrollment payload}
        def call(enrollment)
          result = yield construct_payload(enrollment)
          Success(result)
        end

        private

        def construct_payload(enrollment)
          # returns payload in correct format
          payload = {
            hbx_enrollment: Operations::Transformers::HbxEnrollmentTo::Cv3HbxEnrollment.new.call(enrollment).value!,
            members: enrollment_member_information(enrollment),
          }
          Success(payload)
        end

        def enrollment_member_information(enrollment)
          members = []
          enrollment.hbx_enrollment_members.each do |hem|
            person = hem.person
            members << Operations::Transformers::PersonTo::Cv3Person.new.call(person).value!
          end
          return members
        end
      end
    end
  end
end
