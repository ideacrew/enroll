# frozen_string_literal: true

# This factory is be used to update the CensusMemebers.
# Currently Applied: Family Member updates from UI.

module Factories
  class CensusMemberUpdateFactory
    include ActiveModel::Validations

    def initialize(form)
      @form = form
      @family = Family.find(form.family_id.to_s)
      @family_member = @family.family_members.find(form.id.to_s) if @family

      fetch_people if @family_member
    end

    def is_a_valid_relationship?
      return true unless relationship_changed?

      employer_profiles = fetch_employer_profiles
      return true if employer_profiles.blank?

      !employer_profiles.inject([]) do |results, employer_profile|
        results << employer_sponsored_relation?(@form.relationship, employer_profile)
        results
      end.include?(false)
    end

    private

    def fetch_employer_profiles
      employee_roles = @primary_person.active_employee_roles
      employee_roles.present? ? employee_roles.map(&:employer_profile) : []
    end

    def employer_sponsored_relation?(relation, employer_profile)
      # TODO: Refactor code accordingly to find it the employer contributes to the specific relationship.
      true
    end

    def relationship_changed?
      # TODO: Placeholder to verify if the relationship changed.
      true
    end

    def fetch_people
      @primary_person = @family.primary_person
      @person_in_context = @family_member.person
    end

    def update_census_records(person)
      return unless person.valid? && person.changed?

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
      families = person.families
      return if families.blank?

      family_member_ids = families.map(&:family_members).flatten.select {|fm| fm.person_id == person.id }.map(&:id)

      employee_roles = HbxEnrollment.where(
        :"hbx_enrollment_members.applicant_id".in => family_member_ids,
        :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES + ['coverage_termination_pending'],
        :kind.in => ["employer_sponsored", "employer_sponsored_cobra"]
      ).map(&:employee_role).uniq

      employee_roles.each do |role|
        census_dependent = role.census_employee.census_dependents.where(matching_criteria(person)).first
        update_record(person, census_dependent) if census_dependent.present?
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

      hbx_enrollment.hbx_enrollment_members.where(is_subscriber: false).all.each do |enrollment_member|
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
