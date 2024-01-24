AUDIT_START_DATE = Date.new(2022,10,1)

NO_DC_ADDRESS_IDS = [
# NO ADDRESSES YET
]

people_to_investigate = Person.where(:hbx_id => {"$in" => NO_DC_ADDRESS_IDS})

def home_address_for(person)
  home_address = person.home_address
  return([nil, nil, nil, nil, nil]) if home_address.blank?
  [home_address.address_1, home_address.address_2,
   home_address.city, home_address.state, home_address.zip]
end

def mailing_address_for(person)
  return([nil, nil, nil, nil, nil]) unless person.has_mailing_address?
  home_address = person.mailing_address
  [home_address.address_1, home_address.address_2,
   home_address.city, home_address.state, home_address.zip]
end

def relationship_for(person, family)
  return "self" if (person.id == family.primary_applicant.person_id)
  fm_person = family.primary_applicant.person
  return "unrelated" unless fm_person
  fm_person.person_relationships.select { |r| r.relative_id.to_s == person.id.to_s}.first.try(:kind) || "unrelated"
end

def no_dc_address_reason_for(pers)
  return "homeless" if pers.is_homeless
  return "I am temporarily living outside of DC" if pers.is_temporarily_out_of_state
  nil
end

def find_dc_address_people_for(person, csv)
  families = person.families
  families.each do |fam|
    puts "Family found: #{fam.id}"
    puts "Family member count: #{fam.family_members.count}"
    family_members = fam.family_members.select do |fm|
      (fm.person_id != person.id) &&
        (fm.person.updated_at < AUDIT_START_DATE)
    end
    family_members.each do |fm|
      pers = fm.person
      address_fields = home_address_for(pers)
      mailing_address_fields = mailing_address_for(pers)
      fields = [
          person.hbx_id,
          pers.hbx_id,
          relationship_for(pers, family),
          pers.updated_at.strftime("%Y-%m-%d %H:%M:%S.%L")
        ] +
        address_fields + mailing_address_fields +
        [
          !no_dc_address_reason_for(pers).blank?,
          no_dc_address_reason_for(pers),
        ]
      csv << fields
    end
  end
end


CSV.open("dc_ivl_audit_2023_investigated_cases.csv", "wb") do |csv|
  csv << [
    "Member HBX ID",
    "Related Member HBX ID",
    "Related Member Relationship",
    "Person Updated At",
    "Home Street 1",
    "Home Street 2",
    "Home City",
    "Home State",
    "Home Zip",
    "Mailing Street 1",
    "Mailing Street 2",
    "Mailing City",
    "Mailing State",
    "Mailing Zip",
    "No DC Address",
    "Residency Exemption Reason"
  ]
  people_to_investigate.each do |pti|
    puts "Person Found: #{pti.hbx_id}"
    puts "Family count: #{pti.families.count}"
    find_dc_address_people_for(pti, csv)
  end
end