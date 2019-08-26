# frozen_string_literal: true

module Services
  class CensusEmployeeUpdateService

    def update_census_records(person)
      return unless person.valid?

      if person.active_employee_roles.present?
        update_census_employee_records(person)
      else
        update_census_dependent_records(person)
      end
    end

    def update_census_employee_records(person)
      person.active_employee_roles.each do |role|
        update_record(person, role.census_employee)
      end
    end

    def update_census_dependent_records(person)
      return if person.families.blank?

      person.families.each do |family|
        hbx_enrollments = HbxEnrollment.shop_enrollments_in_enrolled_and_renewal_states(family)
        hbx_enrollments.each do |enrollment|
          census_employee = enrollment.census_employee
          enrollment.hbx_enrollment_members.where(is_subscriber: false).each do |enrollment_member|
            next unless enrollment_member.person.id == person.id

            census_employee.census_dependents.where(matching_criteria(person)).each do |census_dependent|
              update_record(person, census_dependent)
            end
          end
        end
      end
    end

    def update_record(person, record)
      record.update_attributes(build_updated_value_hash(person.changes, required_person_attributes)) if person.changed_attributes

      record.address.update_attributes(build_updated_value_hash(person.mailing_address.changes)) if person.mailing_address.changes && record.address

      email_changes = person.work_or_home_email.changes if person.work_or_home_email
      record.email.update_attributes(build_updated_value_hash(email_changes)) if email_changes
    end

    def create_missing_census_dependents(hbx_enrollment)
      return unless hbx_enrollment.employee_role.present? && hbx_enrollment.is_shop?

      hbx_enrollment.hbx_enrollment_members.where(is_subscriber: false).each do |enrollment_member|
        person = enrollment_member.family_member.person
        census_dependents = hbx_enrollment.employee_role.census_employee.census_dependents
        census_dependents.where(first_name: person.first_name, last_name: person.last_name, dob: person.dob).first_or_create do |census_dependent|
          census_dependent.gender = person.gender
          census_dependent.encrypted_ssn = person.encrypted_ssn
          census_dependent.middle_name = person.middle_name
          census_dependent.name_sfx = person.name_sfx
          census_dependent.employee_relationship = if enrollment_member.primary_relationship == 'child'
                                                     'child_under_26'
                                                   else
                                                     enrollment_member.primary_relationship
                                                   end

        end
      end
    end

    def required_person_attributes
      ["first_name", "middle_name", "last_name", "name_sfx", "dob", "encrypted_ssn", "gender"]
    end

    def matching_criteria(person)
      criteria =
        {
          'first_name' => person.first_name,
          'last_name' => person.last_name,
          'dob' => person.dob
        }
      criteria.keys.each do |changed_attr|
        person.changes.each do |k, v|
          criteria[changed_attr] = v[0] if k == changed_attr
        end
      end
      criteria
    end

    def build_updated_value_hash(attr_changes, req_attrs = nil)
      updated_values = { }
      attr_changes.each do |k, v|
        updated_values[k] = v[1] if req_attrs.nil? || req_attrs&.include?(k)
      end
      updated_values
    end
  end
end
