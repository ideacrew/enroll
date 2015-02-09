class EnrollmentFactory

  attr_accessor :person

  def initialize(person)
    self.person = person
  end

  def self.add_consumer_role(person:, ssn: nil, dob: nil, gender: nil, is_incarcerated:, is_applicant:,
                             is_state_resident:, citizen_status:)

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

  def self.add_broker_role(new_kind, new_npn, new_mailing_address)

    kind = new_kind
    npn = new_npn

    mailing_address = new_mailing_address

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

  def self.add_employee_role(person:, employer:, ssn: nil, dob: nil, gender: nil, hired_on:)
    [:ssn, :dob, :gender].each do |value|
      name = value.id2name

      raise ArgumentError.new("missing value: #{name}, expected as keyword or on person") if person.send(value).blank? and eval(name).blank?
    end

    person.ssn = ssn unless ssn.blank?
    person.dob = dob unless dob.blank?
    person.gender = gender unless gender.blank?

    # Return instance if this role already exists
    role = person.employees.detect { |ee| ee.id == employer.id }

    if role.blank?
      # Assign employee-specifc attributes
      role = person.employees.build(employer: employer, hired_on: hired_on)
    end

    # Add 'self' to personal relationship need detailed implementation
    person.personal_relationships << PersonRelationhip.new()

    family = initialize_families

    if person.save
      if family.save
        family.delete unless role.save
      else
        role.errors.add(:family, "unable to create family")
      end
    else
      role.errors.add(:person, "unable to update person")
    end

    role
  end

  def initialize_families
    family = nil
    if self.person.family.blank?
    # Instantiate new family model need detailed implementation
      family = self.person.build_family()
    end
    return family
  end
end
