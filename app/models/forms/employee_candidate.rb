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
    include ::Forms::DateOfBirthField
    include Validations::USDate.on(:date_of_birth)

    validate :does_not_match_a_different_users_person
    validates :ssn,
              length: { minimum: 9, maximum: 9, message: "SSN must be 9 digits" },
              numericality: true

    def match_census_employees
      census_employees = []
      employers = Organization.where({
        "employer_profile.census_employees" =>  { "$elemMatch" => {
           "dob" => dob,
           "ssn" => ssn,
           "aasm_state" => "eligible"} }
      })
      employers.each do |emp|
        emp.employer_profile.census_employees.each do |ce|
           if (ce.ssn == ssn) && (ce.dob == dob) && (ce.eligible?)
             census_employees << ce
           end
        end
      end
      census_employees
    end

    def match_person
      Person.where({
        :dob => dob,
        :ssn => ssn
      }).first
    end

    def does_not_match_a_different_users_person
       matched_person = match_person
       if matched_person.present?
         if matched_person.user.present?
           if matched_person.user.id.to_s != self.user_id.to_s
             errors.add(
               :exception,
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
