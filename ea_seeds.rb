file = "#{Rails.root}/test.xlsx"
sheet_data = Roo::Spreadsheet.open(file)
# build person & person relationships
2.upto(sheet_data.last_row).each do |row_number|
  data = sheet_data.row(row_number)
  sub_id = data[0].to_i
  member_id = data[1].to_i
  person_relation = data[5]
  first_name = data[13]
  last_name = data[14]
  dob = data[15].to_date
  ssn =  data[16].to_i
  relation = person_relation == "life partner" ? "life_partner" : person_relation
  wk_email = Email.new(kind: "work", address: "dude@dc.gov")
  wk_phone1 = Phone.new(kind: "home", area_code: 202, number: 5551214)
  hm_addr = Address.new(kind: "home", address_1: "609 H St, NE", city: "Washington", state: "DC", zip: "20002")
  primary_person = Person.where(hbx_id: sub_id).first
  person = Person.create!(hbx_id: member_id, is_incarcerated: false, first_name: first_name, last_name: last_name, ssn: ssn, dob: dob, gender: "female", addresses: [hm_addr], phones: [wk_phone1], emails: [wk_email])
  c0 = ConsumerRole.new(person: person, is_incarcerated: false, is_state_resident: true, citizen_status: "us_citizen")
  applicant = sub_id == member_id ? true : false
  c0.is_applicant= applicant
  c0.save!
  person.individual_market_transitions << IndividualMarketTransition.new(role_type: 'consumer',
                                                                         reason_code: 'initial_individual_market_transition_created_using_data_migration',
                                                                         effective_starting_on:  person.consumer_role.created_at.to_date,
                                                                         submitted_at: ::TimeKeeper.datetime_of_record)
  unless primary_person.try(:primary_family).present?
    primary_person = Person.where(hbx_id: sub_id).first
    family = Family.new
    family.add_family_member(primary_person, is_primary_applicant: true)
    family.save!
  end
  if sub_id != member_id
    primary_person = Person.where(hbx_id: sub_id).first
    family = primary_person.primary_family
    person.add_relationship(primary_person, relation, family.id)
    relationship = PersonRelationship.new(kind: PersonRelationship::InverseMap[relation], relative_id: person.id, successor_id: person.id, predecessor_id: primary_person.id, family_id: family.id)
    primary_person.person_relationships << relationship
    primary_person.save!
  end
end
# build family & enrollment
2.upto(sheet_data.last_row).each do |row_number|
  data = sheet_data.row(row_number)
  sub_id = data[0].to_i
  member_id = data[1].to_i
  policy_id = data[2].to_i
  enrollment_status = data[4]
  plan_hios_id = data[6].to_s
  plan_level =  data[7]
  aptc_amount = data[8]
  start_date = data[9].to_i
  end_date = data[10].to_i
  if sub_id == member_id
    
    primary_person = Person.where(hbx_id: sub_id).first
    family = primary_person.primary_family
    primary_person.person_relationships.each { |kin| family.add_family_member(kin.relative) }
    family.save!
    coverage_household = family.active_household.immediate_family_coverage_household
    household = family.active_household
    plan = Plan.where(hios_id: plan_hios_id, metal_level: plan_level, active_year: Date.strptime(start_date.to_s, "%Y%m%d").year).first
    enrollment = HbxEnrollment.new
    enrollment.household = household
    enrollment.hbx_id =policy_id
    enrollment.effective_on =  Date.strptime(start_date.to_s, "%Y%m%d")
    enrollment.submitted_at = Date.today
    enrollment.consumer_role = primary_person.consumer_role
    enrollment.kind = "individual"
    enrollment.enrollment_kind = "open_enrollment"
    enrollment.plan_id = plan.id
    enrollment.applied_aptc_amount = aptc_amount
    coverage_household.coverage_household_members.each do |coverage_member|
      enrollment_member = HbxEnrollmentMember.new_from(coverage_household_member: coverage_member)
      enrollment_member.eligibility_date = enrollment.effective_on
      enrollment_member.coverage_start_on = enrollment.effective_on
      enrollment.hbx_enrollment_members << enrollment_member
    end
    if enrollment_status == "canceled"
      enrollment.aasm_state= 'coverage_canceled'
    elsif enrollment_status == "terminated"
      enrollment.aasm_state= 'coverage_terminated'
      enrollment.terminated_on = Date.strptime(end_date.to_s, "%Y%m%d")
    elsif enrollment_status == "submitted" || enrollment_status == "resubmitted"
      enrollment.aasm_state = 'coverage_selected'
    end
    enrollment.save
  end
end