module Forms
  class EmployeeSignup
    include ActiveModel::Model
    include ActiveModel::Validations

    attr_accessor :person_id
    attr_accessor :employee_id

    # Hidden name information
    attr_accessor :first_name, :middle_name, :last_name
    attr_accessor :name_pfx, :name_sfx
    attr_accessor :gender, :ssn, :dob

    attr_accessor :home_email, :work_email

    attr_accessor :home_phone, :mobile_phone, :work_phone

    include ComposedModel

    composed_of_many :addresses, "::Forms::Address", true
  end
end
