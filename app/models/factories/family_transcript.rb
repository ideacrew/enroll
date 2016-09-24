module Factories
  class FamilyTranscript

    # Expect family_transcript is a hash structured after CV2
    def self.find_or_build_family(family_transcript = {})
      return family_transcript_prototype if family_transcript.blank?

    end

    def self.audit_family(family_transcript)
      return family_transcript_prototype if family_transcript.blank?

    end


    def find_or_build_family(primary_member)
    end

    def find_or_build_consumer_role(consumer)
      # Support citizenship and VLP status override
    end

    def build_employee_role(employee, employer)
    end

    def find_or_build_enrollment(family, enrollment)
      make_employer_sponsored_enrollment
      make_individual_enrollment
    end

  # private
    def family_transcript_prototype
      person = Person.new
      person.build_consumer_role

      family = Family.new
      family.primary_family_member = person
      family.latest_household.hbx_enrollments << HbxEnrollment.new

      { family: family.attributes.merge({
                    family_members: [
                        family.family_members.first.attributes
                      ],
                    irs_groups: [
                        family.irs_groups.first.attributes
                      ],
                    households: [
                        family.households.first.attributes.merge({
                          hbx_enrollments: [
                              family.households.first.hbx_enrollments.first.attributes
                            ]
                          })
                      ]
                  }),
        people: [
                    person.attributes.merge({
                        consumer_role: person.consumer_role.attributes
                      })
                  ] }
    end
  end

  class FamilyTranscriptError < StandardError; end
end
