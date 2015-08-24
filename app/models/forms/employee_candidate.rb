module Forms
  class EmployeeCandidate
    include ActiveModel::Model
    include ActiveModel::Validations

    include PeopleNames
    include SsnField
    attr_accessor :gender

    attr_accessor :user_id

    validates_presence_of :first_name, :allow_blank => nil
    validates_presence_of :last_name, :allow_blank => nil
    validates_presence_of :gender, :allow_blank => nil
    validates_presence_of :dob
    # include ::Forms::DateOfBirthField
    #include Validations::USDate.on(:date_of_birth)

    validate :does_not_match_a_different_users_person
    validates :ssn,
              length: { minimum: 9, maximum: 9, message: "SSN must be 9 digits" },
              numericality: true

    attr_reader :dob

    def dob=(val)
      @dob = Date.strptime(val, "%Y-%m-%d") rescue nil
    end

    # TODO fix and use as the only way to match census employees for the employee flow or blow this away
    def match_census_employees
      CensusEmployee.matchable(ssn, dob).to_a
    end

    def match_person
      Person.where({
        :dob => dob,
        :encrypted_ssn => Person.encrypt_ssn(ssn)
      }).first
    end

  def does_not_match_a_different_users_person
    matched_person = match_person
    if matched_person.present?
      if matched_person.user.present?
        if matched_person.user.id.to_s != self.user_id.to_s
          errors.add(
            :base,
            "An account already exists for #{first_name} #{last_name}."
          )
        end
      end
    end
    true
  end

    def persisted?
      false
    end
  end
end
