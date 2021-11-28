module Forms
  class ResidentCandidate
    include Acapi::Notifiers
    include ActiveModel::Model
    include ActiveModel::Validations

    include PeopleNames
    include SsnField
    include ::L10nHelper
    attr_accessor :gender
    attr_accessor :user_id
    attr_accessor :no_ssn
    attr_accessor :dob_check #hidden input filed for one time DOB warning
    attr_accessor :is_applying_coverage

    validates_presence_of :first_name, :allow_blank => nil
    validates_presence_of :last_name, :allow_blank => nil
    validates_presence_of :gender, :allow_blank => nil
    validates_presence_of :dob
    # include ::Forms::DateOfBirthField
    #include Validations::USDate.on(:date_of_birth)

    validate :does_not_match_a_different_users_person
    validate :dob_not_in_future
    validate :age_less_than_18
    validate :uniq_name_ssn_dob, if: :state_based_policy_satisfied?
    attr_reader :dob

    def dob=(val)
      @dob = Date.strptime(val, "%Y-%m-%d") rescue nil
    end

    def match_person
      match_criteria, records = Operations::People::Match.new.call({:dob => dob,
                                                                    :last_name => last_name,
                                                                    :first_name => first_name,
                                                                    :ssn => ssn})

      return nil if records.count == 0

      if (match_criteria == :dob_present && ssn.present? && records.first.employer_staff_roles?) ||
         (match_criteria == :dob_present && ssn.blank?) ||
         match_criteria == :ssn_present
        records.first
      end
    end

    def uniq_ssn
      return true if ssn.blank?
      same_ssn = Person.where(encrypted_ssn: Person.encrypt_ssn(ssn))
      if same_ssn.present? && same_ssn.first.try(:user)
        errors.add(:ssn_taken,
                  #{}"This Social Security Number has been taken on another account.  If this is your correct SSN, and you don’t already have an account, please contact #{HbxProfile::CallCenterName} at #{HbxProfile::CallCenterPhoneNumber}.")
                  "The social security number you entered is affiliated with another account.")
      end
    end

    def state_based_policy_satisfied?
      @configuration = EnrollRegistry[:person_match_policy].settings.map(&:to_h).each_with_object({}) do |s,c|
        c.merge!(s[:key] => s[:item])
      end

      ["first_name", "last_name"].all? { |e| @configuration[:ssn_present].include?(e) }
    end

    # rubocop:disable Style/GuardClause
    def uniq_name_ssn_dob
      return true if ssn.blank?

      person_with_ssn = Person.where(encrypted_ssn: Person.encrypt_ssn(ssn)).first
      matched_person = match_person

      if matched_person != person_with_ssn
        errors.add(:base, l10n("insured.match_person.ssn_dob_name_error", site_short_name: EnrollRegistry[:enroll_app].settings(:short_name).item,
                                                                          contact_center_phone_number: EnrollRegistry[:enroll_app].settings(:contact_center_short_number).item,
                                                                          contact_center_tty_number: EnrollRegistry[:enroll_app].settings(:contact_center_tty_number).item,
                                                                          contact_center_name: EnrollRegistry[:enroll_app].settings(:contact_center_name).item))
        log("ERROR: unable to match or create Person record, SSN exists with different DOB and Name", {:severity => "error"})
      end
    end
    # rubocop:enable Style/GuardClause

    def does_not_match_a_different_users_person
      matched_person = match_person
      if matched_person.present?
        if matched_person.user.present?
          if matched_person.user.id.to_s != self.user_id.to_s
            errors.add(
                :base,
                "#{first_name} #{last_name} is already affiliated with another account."
            )
          end
        end
      end
      true
    end

    def dob_not_in_future

      if self.dob && self.dob > ::TimeKeeper.date_of_record
        errors.add(
            :dob,
            "#{dob} can't be in the future.")
        self.dob=""
      end
    end

    # Throw Error/Warning if user age is less than 18
    def age_less_than_18
      if self.dob_check == "false" || self.dob_check.blank?
        if ::TimeKeeper.date_of_record.year - self.dob.year < 18
          errors.add(:base, "Please verify your date of birth. If it's correct, please continue.")
          self.dob_check = true
        else
          self.dob_check = false
        end
      end
    end

    def persisted?
      false
    end
  end
end
