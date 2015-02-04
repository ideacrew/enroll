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
   
  def add_broker_role(new_kind, new_npn, new_mailing_address)

    kind = new_kind
    npn = new_npn
    maling_address = new_maling_address
   
    family = initialize_families
    
    broker_role = nil
    
    if self.person.broker.blank?
      # Assign broker-specifc attributes
      broker_role = self.person.build_broker(mailing_address: mailing_address, npn: npn, kind: kind)
    end
    
    self.person.save
    broker_role.save if broker_role.present?
    family.save if family.present?

    # Return new instance
    return broker_role

  end

  def add_employee_role(new_employer, new_ssn, new_dob, new_gender, new_date_of_hire)
    # Return instance if this role already exists
    # Verify/assign required additional local attributes
    ssn = new_ssn
    dob = new_dob
    gender = new_gender

    employee_role = nil
    
    if self.person.employee.blank?
      # Assign employee-specifc attributes
      employee_role = self.person.build_employee(employer: new_employer, date_of_hire: new_date_of_hire)
    end

    # Add 'self' to personal relationship
    self.person.personal_relationships << PersonRelationhip.new()
    
    family = initialize_families

    # Persist results?
    self.person.save
    employee_role.save if employee_role.present?
    family.save if family.present?

    # Return new instance
    return employee_role
  end
  
  def initialize_families
    family = nil
    if self.person.families.blank?
    # Instantiate new family model
      family = self.person.families.build()
    end
    return family
  end
end
