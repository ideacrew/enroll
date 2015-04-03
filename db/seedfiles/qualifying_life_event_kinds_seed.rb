puts "*"*80
puts "::: Cleaning QualifyingLifeEventKinds :::"
QualifyingLifeEventKind.delete_all

QualifyingLifeEventKind.create!(
    title: "I've started a new job", 
    kind: "add",
    reason: " ",
    edi_code: "28-INITIAL ENROLLMENT", 
    market_kind: "shop", 
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: true, 
    ordinal_position: 10,
    description: "Enroll due to becoming newly eligibile"
  )


QualifyingLifeEventKind.create!(
    title: "I've married", 
    kind: "add",
    reason: " ",
    edi_code: "32-MARRIAGE", 
    market_kind: "shop", 
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: true, 
    ordinal_position: 15,
    description: "Enroll or add a family member because of marriage"
  )

QualifyingLifeEventKind.create!(
    title: "I've entered into a legal domestic partnership", 
    kind: "add",
    reason: " ",
    edi_code: "33-ENTERING DOMESTIC PARTNERSHIP", 
    market_kind: "shop", 
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: true, 
    ordinal_position: 20,
    description: "Enroll or add a family member due to a new domestic partnership"
  )

QualifyingLifeEventKind.create!(
    title: "I've had a baby", 
    kind: "add",
    reason: " ",
    edi_code: "02-BIRTH", 
    market_kind: "shop", 
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: true, 
    ordinal_position: 25,
    description: "Enroll or add a family member due to birth"
  )

QualifyingLifeEventKind.create!(
    title: "I've adopted a child", 
    kind: "add",
    reason: " ",
    edi_code: "05-ADOPTION", 
    market_kind: "shop", 
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: true, 
    ordinal_position: 30,
    description: "Enroll or add a family member due to adoption"
  )

QualifyingLifeEventKind.create!(
    title: "Myself or a family member has lost other coverage", 
    kind: "add",
    reason: " ",
    edi_code: "33-LOST ACCESS TO MEC", 
    market_kind: "shop", 
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: true, 
    ordinal_position: 35,
    description: "Enroll or add a family member due to loss of eligibility for other coverage"
  )

QualifyingLifeEventKind.create!(
    title: "divorce", 
    kind: "drop",
    reason: " ",
    edi_code: "01-DIVORCE", 
    market_kind: "shop", 
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: true, 
    ordinal_position: 40,
    description: "Remove a family member due to divorce"
  )

QualifyingLifeEventKind.create!(
    title: "death", 
    kind: "drop",
    reason: " ",
    edi_code: "03-DEATH", 
    market_kind: "shop", 
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: true, 
    ordinal_position: 45,
    description: "Remove a family member due to death"
  )

QualifyingLifeEventKind.create!(
    title: "child_age_off", 
    kind: "drop",
    reason: "child_age_off",
    edi_code: "33-CHILD AGE OFF", 
    market_kind: "shop", 
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: true, 
    ordinal_position: 50,
    description: "Remove a child who is no longer eligible due to turning age 26"
  )

QualifyingLifeEventKind.create!(
    title: "drop_self_due_to_new_eligibility", 
    kind: "drop",
    reason: "terminate_benefit",
    edi_code: "07-TERMINATION OF BENEFITS", 
    market_kind: "shop", 
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: true, 
    ordinal_position: 55,
    description: "Drop coverage for myself or family member due to new eligibility for other coverage"
  )

QualifyingLifeEventKind.create!(
    title: "drop_family_member_due_to_new_elgibility", 
    kind: "drop",
    reason: "drop_family_member_due_to_new_elgibility",
    edi_code: "07-TERMINATION OF BENEFITS", 
    market_kind: "shop", 
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: true, 
    ordinal_position: 60,
    description: "Drop coverage for a family member due to their new eligibility for other coverage"
  )

QualifyingLifeEventKind.create!(
    title: "I've moved", 
    kind: "administrative",
    reason: "relocate",
    edi_code: "43-CHANGE OF LOCATION", 
    market_kind: "shop", 
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: false, 
    ordinal_position: 65,
    description: "Drop coverage due to a permanent move outside of my current plan's service area"
  )

QualifyingLifeEventKind.create!(
    title: "exceptional_circumstances", 
    kind: "administrative",
    reason: "exceptional_circumstances",
    edi_code: "EX-EXCEPTIONAL CIRCUMSTANCES", 
    market_kind: "shop", 
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: false, 
    ordinal_position: 70,
    description: "Enroll due to an inadvertent or erroneous enrollment or another exceptional circumstance"
  )

QualifyingLifeEventKind.create!(
    title: "contract_violation", 
    kind: "administrative",
    reason: "contract_violation",
    edi_code: "33-CONTRACT VIOLATION", 
    market_kind: "shop", 
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: false, 
    ordinal_position: 75,
    description: "Enroll due to contract violation"
  )

puts "::: QualifyingLifeEventKinds Complete :::"
puts "*"*80
