module Forms
  class EmployeeSignup
    include ActiveModel::Model
    include ActiveModel::Validations

    attr_accessor :person_id
    attr_accessor :employee_id
    attr_accessor :user_id

    # Hidden name information
    attr_accessor :first_name, :middle_name, :last_name
    attr_accessor :name_pfx, :name_sfx
    attr_accessor :gender, :date_of_birth
    attr_reader :ssn

    attr_accessor :home_email, :work_email

    attr_accessor :home_phone, :mobile_phone, :work_phone

    include ComposedModel

    composed_of_many :addresses, "::Forms::Address", true

    validates_presence_of :first_name, :allow_blank => nil
    validates_presence_of :last_name, :allow_blank => nil
    include Validations::USDate.on(:date_of_birth)

    validates :ssn,
      length: { minimum: 9, maximum: 9, message: "SSN must be 9 digits" },
      numericality: true

    def dob
      Date.strptime(date_of_birth, "%m/%d/%Y") rescue nil
    end

    def ssn=(new_ssn)
      if !new_ssn.blank?
        @ssn = new_ssn.to_s.gsub(/\D/, '')
      end
    end
  end
end
