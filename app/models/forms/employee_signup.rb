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

    include ComposedModel

    composed_of_many :phones, "::Forms::Phone"
  end
end
