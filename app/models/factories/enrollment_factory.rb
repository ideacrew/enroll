class EnrollmentFactory

  attr_accessor :person

  def initialize(person)
    self.person = person
  end

  def add_consumer_role(new_ssn, new_dob, new_gender, new_is_incarcerated, new_is_applicant,
                        new_is_state_resident, new_citizen_status)

    ssn = new_ssn
    dob = new_dob
    gender = new_gender
    is_incarcerated = new_is_incarcerated
    is_applicant = new_is_applicant
    is_state_resident = new_is_state_resident
    citizen_status = new_citizen_status

    # Assign consumer-specifc attributes
    consumer_role = self.person.build_consumer(ssn: ssn,
                                               dob: dob,
                                               gender: gender,
                                               is_incarcerated: is_incarcerated,
                                               is_applicant: is_applicant,
                                               is_state_resident: is_state_resident,
                                               citizen_status: citizen_status)
   self.person.save
   consumer_role.save

   return consumer_role
  
  end
   
  def add_broker_role
    # Instantiate new family model
    family = self.person.families.build()

    # Assign broker-specifc attributes
    broker_role = self.person.build_broker()

    self.person.save
    broker_role.save
    family.save

    # Return new instance
    return broker_role

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
    return employee_role
  end

end
