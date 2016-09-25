module Factories
  class FamilyTranscript

    # Expect family_transcript is a hash structured after CV2
    def find_or_build_local(family_transcript = {})
      return family_transcript_prototype if family_transcript.blank?

      local_people = family_transcript.people.reduce([]) { |list, person| list << find_or_build_person(person) }
      local_family = find_or_build_family(family_transcript.family)
      local_family_enrollments = family_transcript.households.each do |household|
        household.hbx_enrollments.each { |hbx_enrollment|  find_or_build_hbx_enrollment(hbx_enrollment, family_transcript.family) }
      end

      { family: family.local_family({
            family_members: [local_family.family_members],
            irs_groups: [local_family.irs_groups],
            households: [local_family.households({
                            hbx_enrollments: [local_family_enrollments]
                          })
                      ]
          }),
        people: [local_people]
      }
    end

    def audit_family(family_transcript)
      local_family = find_or_build_local(family_transcript)

    end

    def difference(base_record, compare_record)
      differences = HashWithIndifferentAccess.new
      all_keys = (base_record.keys + compare_record.keys).uniq!
      all_keys.each do |k|
        next if base_record[k].blank? && compare_record[k].blank?

        if base_record[k].blank?
          differences[:add] ||= {}
          differences[:add][k] = compare_record[k]
        elsif compare_record[k].blank?
          differences[:remove] ||= {}
          differences[:remove][k] = base_record[k]
        elsif base_record[k].is_a?(Array) && compare_record[k].is_a?(Array)
          differences[:array] ||= {}
          old_values = base_record[k] - compare_record[k]
          new_values = compare_record[k] - base_record[k]
          differences[:array][k] = { add: new_values, remove: old_values }.delete_if { |_, vv| vv.blank? }
# binding.pry
          differences[:array][k].delete_if { |_, v| v.blank? }
        else
          if base_record[k] != compare_record[k]
            differences[:update] ||= {}
            differences[:update][k] = compare_record[k]
          end
        end
      end

      differences
    end

    # Use 
    def find_or_build_family(transcript_primary_member)

    end

    def find_or_build_person(transcript_person)
      # Support citizenship and VLP status override
    end

    def build_consumer_role(transcript_consumer)
      # Support citizenship and VLP status override
    end

    def build_employee_role(transcript_employee, transcript_employer)
    end

    def find_or_build_hbx_enrollment(transcript_family, transcript_hbx_enrollment)
      enrollment = match_hbx_enrollment(hbx_enrollment)

      make_employer_sponsored_enrollment
      make_individual_enrollment
    end

  private

    def match_family(family)

    end

    def match_person(transcript_person)
      Person.match_existing_person(transcript_person)
    end

    def match_hbx_enrollment(hbx_enrollment)

    end


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
