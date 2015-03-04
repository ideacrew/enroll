puts "*"*80
puts "::: Cleaning LifeEvents :::"
Employer.delete_all

LifeEvent.create!(
    title: "new_hire", 
    kind: "add_member",
    edi_reason: "28-INITIAL ENROLLMENT", 
    market_kind: "shop", 
    sep_in_days: 30, 
    is_self_attested: true, 
    description: "Enroll due to becoming newly eligibile"
  )

LifeEvent.create!(
    title: "birth", 
    kind: "add_member",
    edi_reason: "02-BIRTH", 
    market_kind: "shop", 
    sep_in_days: 30, 
    is_self_attested: true, 
    description: "Add a family member because of birth"
  )

LifeEvent.create!(
    title: "adoption", 
    kind: "add_member",
    edi_reason: "05-ADOPTION", 
    market_kind: "shop", 
    sep_in_days: 30, 
    is_self_attested: true, 
    description: "Add a family member because of adoption"
  )

LifeEvent.create!(
    title: "marriage", 
    kind: "add_member",
    edi_reason: "32-MARRIAGE", 
    market_kind: "shop", 
    sep_in_days: 30, 
    is_self_attested: true, 
    description: "Add a family member because of marriage"
  )

LifeEvent.create!(
    title: "entering_domestic_partnership", 
    kind: "add_member",
    edi_reason: "33-ENTERING DOMESTIC PARTNERSHIP", 
    market_kind: "shop", 
    sep_in_days: 30, 
    is_self_attested: true, 
    description: "Add a family member because of new domestic partnership"
  )

LifeEvent.create!(
    title: "lost_access_to_mec", 
    kind: "add_member",
    edi_reason: "33-LOST ACCESS TO MEC", 
    market_kind: "shop", 
    sep_in_days: 30, 
    is_self_attested: true, 
    description: "Add a family member due to their loss of eligibility for other coverage"
  )

LifeEvent.create!(
    title: "drop_self_due_to_new_eligibility", 
    kind: "terminate_benefit",
    edi_reason: "07-TERMINATION OF BENEFITS", 
    market_kind: "shop", 
    sep_in_days: 30, 
    is_self_attested: true, 
    description: "Drop my coverage due to my new eligibility for other coverage"
  )

LifeEvent.create!(
    title: "drop_family_member_due_to_new_elgibility", 
    kind: "drop_member",
    edi_reason: "07-TERMINATION OF BENEFITS", 
    market_kind: "shop", 
    sep_in_days: 30, 
    is_self_attested: true, 
    description: "Drop coverage for a family member due to their new eligibility for other coverage"
  )

LifeEvent.create!(
    title: "child_age_off", 
    kind: "drop_member",
    edi_reason: "33-CHILD AGE OFF", 
    market_kind: "shop", 
    sep_in_days: 30, 
    is_self_attested: true, 
    description: "Remove a child who is no longer eligible due to turning age 26"
  )

LifeEvent.create!(
    title: "divorce", 
    kind: "drop_member",
    edi_reason: "01-DIVORCE", 
    market_kind: "shop", 
    sep_in_days: 30, 
    is_self_attested: true, 
    description: "Remove a family member due to divorce"
  )

LifeEvent.create!(
    title: "death", 
    kind: "drop_member",
    edi_reason: "03-DEATH", 
    market_kind: "shop", 
    sep_in_days: 30, 
    is_self_attested: true, 
    description: "Remove a family member due to death"
  )

LifeEvent.create!(
    title: "relocate", 
    kind: "administrative",
    edi_reason: "43-CHANGE OF LOCATION", 
    market_kind: "shop", 
    sep_in_days: 30, 
    is_self_attested: false, 
    description: "Enroll in new plan due to a permanent move outside of my current plan's service area"
  )

LifeEvent.create!(
    title: "exceptional_circumstances", 
    kind: "administrative",
    edi_reason: "EX-EXCEPTIONAL CIRCUMSTANCES", 
    market_kind: "shop", 
    sep_in_days: 30, 
    is_self_attested: false, 
    description: "Enroll due to an inadvertent or erroneous enrollment or another exceptional circumstance"
  )

LifeEvent.create!(
    title: "contract_violation", 
    kind: "administrative",
    edi_reason: "33-CONTRACT VIOLATION", 
    market_kind: "shop", 
    sep_in_days: 30, 
    is_self_attested: false, 
    description: "Enroll due to contract violation"
  )

puts "::: LifeEvents Complete :::"
puts "*"*80
