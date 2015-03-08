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
    consumer_role = person.build_consumer_role(ssn: ssn,
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

    if person.broker_role.blank?
      # Assign broker-specifc attributes
      #broker_role = person.build_broker(mailing_address: mailing_address, npn: npn, kind: kind)
      broker_role = person.build_broker_role(npn: npn)
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

  def self.add_employee_role(user: nil, employer_profile:,
        name_pfx: nil, first_name:, middle_name: nil, last_name:, name_sfx: nil,
        ssn:, dob:, gender:, hired_on:
        )
    # TODO: find existing person or create a new person
    people = Person.match_by_id_info(ssn: ssn)
    person = case people.count
    when 1
      people.first
    when 0
      Person.create(
        user: user,
        name_pfx: name_pfx,
        first_name: first_name,
        middle_name: middle_name,
        last_name: last_name,
        name_sfx: name_sfx,
        ssn: ssn,
        dob: dob,
        gender: gender,
      )
    else
      # what am I doing here?  More than one person had the same SSN?
      nil
    end

    employer_census_family = employer_profile.linkable_employee_family_by_person(person)

    # Return instance if this role already exists
    roles = person.employee_roles.where(
        "employer_profile_id" => employer_profile.id.to_s,
        "hired_on" => employer_census_family.census_employee.hired_on
      )

    role = case roles.count
    when 0
      # Assign employee-specifc attributes
      person.employee_roles.build(employer_profile: employer_profile, hired_on: hired_on)
    when 1
      roles.first
    else
      # What am I doing here?
      nil
    end

    employer_census_family.link_employee_role(role)

    # Add 'self' to personal relationship need detailed implementation
    # person.person_relationships << PersonRelationhip.new()

    family, primary_applicant = self.initialize_family(person)
    # TODO: create extra family stuff if in census

    save_all_or_delete_new(person, family, primary_applicant, role, employer_census_family)
    return role, family
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
