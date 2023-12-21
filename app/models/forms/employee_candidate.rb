# frozen_string_literal: true

module Forms
  class EmployeeCandidate
    include ActiveModel::Model
    include ActiveModel::Validations
    include L10nHelper
    include Config::ContactCenterModelConcern

    include PeopleNames
    include SsnField
    attr_accessor :gender, :user_id, :dob_check, :is_applying_coverage, :invalid_match_attempts

    validates_presence_of :first_name, :allow_blank => nil
    validates_presence_of :last_name, :allow_blank => nil
    validates_presence_of :gender, :allow_blank => nil
    validates_presence_of :dob
    # include ::Forms::DateOfBirthField
    #include Validations::USDate.on(:date_of_birth)

    validate :does_not_match_a_different_users_person
    validates :ssn,
              length: {minimum: 9, maximum: 9, message: "SSN must be 9 digits"},
              allow_blank: true,
              numericality: true
    validate :dob_not_in_future

    attr_reader :dob

    def dob=(val)
      @dob = val.class == Date ? val : Date.strptime(val, "%Y-%m-%d") rescue nil
    end

    # TODO fix and use as the only way to match census employees for the employee flow or blow this away
    def match_census_employees
      if no_ssn == "1"
        CensusEmployee.matchable_by_dob_lname_fname(dob, first_name, last_name).to_a
      else
        CensusEmployee.matchable(ssn, dob).to_a + CensusEmployee.unclaimed_matchable(ssn, dob).to_a
      end
    end

    def match_person
      if !ssn.blank?
        Person.where({
                       :dob => dob,
                       :encrypted_ssn => Person.encrypt_ssn(ssn)
                   }).first || match_ssn_employer_person
      else
        Person.where({
                       :dob => dob,
                       :last_name => /^#{last_name}$/i,
                       :first_name => /^#{first_name}$/i,
                   }).first
      end
    end

    def match_ssn_employer_person
      potential_person = Person.where({
                       :dob => dob,
                       :last_name => /^#{last_name}$/i,
                       :first_name => /^#{first_name}$/i,
                   }).first
      if potential_person.present?
        potential_person.update(gender: gender) if potential_person.gender.blank?
        potential_person.update(ssn: ssn) if potential_person.ssn.blank?
        return potential_person if potential_person.employer_staff_roles?
      end
      nil
    end

    def does_not_match_a_different_users_person
      matched_person = match_person
      if matched_person.present? && matched_person.user.present?
        current_user_id = self.user_id.to_s
        matched_person_user_id = matched_person.user.id.to_s
        if matched_person_user_id != current_user_id && !EnrollRegistry.feature_enabled?(:lock_account_for_unsuccessful_match_attempts)
          errors.add(
            :base,
            "#{first_name} #{last_name} is already affiliated with another account"
          )
        end
      end
      true
    end

    def validate_and_lock_account
      return unless EnrollRegistry.feature_enabled?(:lock_account_for_unsuccessful_match_attempts)
      max_match_attempts = EnrollRegistry[:employee_match_max_attempts].item.to_i

      if invalid_match_attempts >= max_match_attempts
        message = l10n("insured.employee_roles.unsuccessful_match_attempts_exceeded", contact_center_name: contact_center_name, contact_center_phone_number: contact_center_phone_number)
        errors.add(
          :base,
          message
        )
        current_user.lock!
      else
        message = l10n("insured.employee_roles.unsuccessful_match_attempts")
        errors.add(
          :base, message
        )
      end
    end

    def current_user
      User.find(user_id) if user_id.present?
    end

    def dob_not_in_future
      if self.dob && self.dob > ::TimeKeeper.date_of_record
        errors.add(
            :dob,
            "#{dob} can't be in the future.")
        self.dob=""
      end
    end

    def persisted?
      false
    end
  end
end
