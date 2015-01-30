class EnrollmentFactory

  attr_accessor :person

  def initialize(person)
    self.person = person
  end

  def add_consumer_role
  end

  def add_employee_role(new_employer, new_ssn, new_dob, new_gender, new_date_of_hire)
    # Return instance if this role already exists
    # Verify/assign required additional local attributes
    ssn = new_ssn
    dob = new_dob
    gender = new_gender

    # Assign employee-specifc attributes
    employee_role = self.person.build_employee(employer: new_employer, date_of_hire: new_date_of_hire)

    # Add 'self' to personal relationship
    self.person.personal_relationships << PersonRelationhip.new()

    # Instantiate new family model
    family = self.person.families.build()

    # Persist results?
    self.person.save
    employee_role.save
    family.save

    # Return new instance
    employee_role
  end

end
