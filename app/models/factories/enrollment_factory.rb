class EnrollmentFactory

  attr_accessor :person

  def initialize(person)
    self.person = person
  end

  def self.add_consumer_role(person:, new_ssn: nil, new_dob: nil, new_gender: nil, new_is_incarcerated:, new_is_applicant:,
                             new_is_state_resident:, new_citizen_status:)

    [:new_is_incarcerated, :new_is_applicant, :new_is_state_resident, :new_citizen_status].each do |value|
      name = value.id2name
      raise ArgumentError.new("missing value: #{name}, expected as keyword ") if eval(name).blank?
    end

    ssn = new_ssn
    dob = new_dob
    gender = new_gender
    is_incarcerated = new_is_incarcerated
    is_applicant = new_is_applicant
    is_state_resident = new_is_state_resident
    citizen_status = new_citizen_status

    # Assign consumer-specifc attributes
    consumer_role = person.build_consumer(ssn: ssn,
                                               dob: dob,
                                               gender: gender,
                                               is_incarcerated: is_incarcerated,
                                               is_applicant: is_applicant,
                                               is_state_resident: is_state_resident,
                                               citizen_status: citizen_status)
   if person.save
      consumer_role.save
    else
      consumer_role.errors.add(:person, "unable to update person")
    end

   return consumer_role

  end

  def self.add_broker_role(person:, new_kind:, new_npn:, new_mailing_address:)

    [:new_kind, :new_npn, :new_mailing_address].each do |value|
      name = value.id2name

      raise ArgumentError.new("missing value: #{name}, expected as keyword ") if eval(name).blank?
    end

    kind = new_kind
    npn = new_npn

    mailing_address = new_mailing_address

    family, = self.initialize_family(person)

    broker_role = nil

    if person.broker.blank?
      # Assign broker-specifc attributes
      #broker_role = person.build_broker(mailing_address: mailing_address, npn: npn, kind: kind)
      broker_role = person.build_broker(npn: npn)
    end

    if person.save
      if family.save
        family.delete unless broker_role.save
      else
        broker_role.errors.add(:family, "unable to create family")
      end
    else
      broker_role.errors.add(:person, "unable to update person")
    end

    # Return new instance
    return broker_role

  end

  def self.add_employee_role(person:, employer_census_employee_family:, ssn: nil, dob: nil, gender: nil, hired_on:)
    [:ssn, :dob, :gender].each do |value|
      name = value.id2name

      raise ArgumentError.new("missing value: #{name}, expected as keyword or on person") if person.send(value).blank? and eval(name).blank?
    end

    person.ssn = ssn unless ssn.blank?
    person.dob = dob unless dob.blank?
    person.gender = gender unless gender.blank?

    employer = employer_census_employee_family.employer

    # Return instance if this role already exists
    role = person.employees.detect { |ee| ee.id == employer.id }

    if role.blank?
      # Assign employee-specifc attributes
      role = person.employees.build(employer: employer, hired_on: hired_on)
    end

    employer_census_employee_family.link_employee(role)

    # Add 'self' to personal relationship need detailed implementation
    #person.person_relationships << PersonRelationhip.new()

    family, primary_applicant = self.initialize_family(person)
    save_all_or_delete_new(person, family, primary_applicant, role, employer_census_employee_family)
    role
  end

  private

  def self.initialize_family(person)
    family = person.family
    family = person.build_family() if family.blank?
    primary_applicant = family.primary_applicant
    primary_applicant = initialize_primary_applicant(family, person) if primary_applicant.blank?
    return family, primary_applicant
  end

  def self.initialize_primary_applicant(family, person)
    family_member = family.family_members.build(
      person_id: person.id,
      is_primary_applicant: true,
      is_coverage_applicant: true)
  end

  def self.save_all_or_delete_new(*list)
    objects_to_save = list.reject {|o| !o.changed?}
    num_saved = objects_to_save.count {|o| o.save}
    if num_saved < objects_to_save.count
      objects_to_save.each {|o| o.delete}
      false
    else
      true
    end
  end
end
