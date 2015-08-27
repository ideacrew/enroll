puts "*"*80
puts "::: Cleaning QualifyingLifeEventKinds :::"
QualifyingLifeEventKind.delete_all

QualifyingLifeEventKind.create!(
    title: "I've started a new job", 
    action_kind: "add_benefit",
    reason: " ",
    edi_code: "28-INITIAL ENROLLMENT", 
    market_kind: "shop", 
    effective_on_kinds: ["first_of_month"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: true, 
    ordinal_position: 10,
    tool_tip: "Enroll due to becoming newly eligibile"
  )


QualifyingLifeEventKind.create!(
    title: "I've married", 
    action_kind: "add_benefit",
    reason: " ",
    edi_code: "32-MARRIAGE", 
    market_kind: "shop", 
    effective_on_kinds: ["first_of_month"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: true, 
    ordinal_position: 15,
    tool_tip: "Enroll or add a family member because of marriage"
  )

QualifyingLifeEventKind.create!(
    title: "I've entered into a legal domestic partnership", 
    action_kind: "add_benefit",
    reason: " ",
    edi_code: "33-ENTERING DOMESTIC PARTNERSHIP", 
    market_kind: "shop", 
    effective_on_kinds: ["first_of_month"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: true, 
    ordinal_position: 20,
    tool_tip: "Enroll or add a family member due to a new domestic partnership"
  )

QualifyingLifeEventKind.create!(
    title: "I've had a baby", 
    action_kind: "add_benefit",
    reason: " ",
    edi_code: "02-BIRTH", 
    market_kind: "shop", 
    effective_on_kinds: ["date_of_event"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: true, 
    ordinal_position: 25,
    tool_tip: "Enroll or add a family member due to birth"
  )

QualifyingLifeEventKind.create!(
    title: "I've adopted a child", 
    action_kind: "add_benefit",
    reason: " ",
    edi_code: "05-ADOPTION", 
    market_kind: "shop", 
    effective_on_kinds: ["date_of_event"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: true, 
    ordinal_position: 30,
    tool_tip: "Enroll or add a family member due to adoption"
  )

QualifyingLifeEventKind.create!(
    title: "Myself or a family member has lost other coverage", 
    action_kind: "add_benefit",
    reason: " ",
    edi_code: "33-LOST ACCESS TO MEC", 
    market_kind: "shop", 
    effective_on_kinds: ["first_of_month"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: true, 
    ordinal_position: 35,
    tool_tip: "Enroll or add a family member due to loss of eligibility for other coverage"
  )

QualifyingLifeEventKind.create!(
    title: "I've divorced", 
    action_kind: "drop_member",
    reason: " ",
    edi_code: "01-DIVORCE", 
    market_kind: "shop", 
    effective_on_kinds: ["first_of_month"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: true, 
    ordinal_position: 40,
    tool_tip: "Remove a family member due to divorce"
  )

QualifyingLifeEventKind.create!(
    title: "A family member has died", 
    action_kind: "drop_member",
    reason: " ",
    edi_code: "03-DEATH", 
    market_kind: "shop", 
    effective_on_kinds: ["first_of_month"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: true, 
    ordinal_position: 45,
    tool_tip: "Remove a family member due to death"
  )

QualifyingLifeEventKind.create!(
    title: "My child has lost coverage due to age", 
    action_kind: "drop_member",
    reason: "child_age_off",
    edi_code: "33-CHILD AGE OFF", 
    market_kind: "shop", 
    effective_on_kinds: ["first_of_month"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: true, 
    ordinal_position: 50,
    tool_tip: "Remove a child who is no longer eligible due to turning age 26"
  )

QualifyingLifeEventKind.create!(
    title: "drop_self_due_to_new_eligibility", 
    action_kind: "drop_member",
    reason: "terminate_benefit",
    edi_code: "07-TERMINATION OF BENEFITS", 
    market_kind: "shop", 
    effective_on_kinds: ["first_of_month"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: true, 
    ordinal_position: 55,
    tool_tip: "Drop coverage for myself or family member due to new eligibility for other coverage"
  )

QualifyingLifeEventKind.create!(
    title: "drop_family_member_due_to_new_elgibility", 
    action_kind: "drop_member",
    reason: "drop_family_member_due_to_new_elgibility",
    edi_code: "07-TERMINATION OF BENEFITS", 
    market_kind: "shop", 
    effective_on_kinds: ["first_of_month"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: true, 
    ordinal_position: 60,
    tool_tip: "Drop coverage for a family member due to their new eligibility for other coverage"
  )

QualifyingLifeEventKind.create!(
    title: "I've moved", 
    action_kind: "administrative",
    reason: "relocate",
    edi_code: "43-CHANGE OF LOCATION", 
    market_kind: "shop", 
    effective_on_kinds: ["first_of_month"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: false, 
    ordinal_position: 65,
    tool_tip: "Drop coverage due to a permanent move outside of my current plan's service area"
  )

QualifyingLifeEventKind.create!(
    title: "exceptional_circumstances", 
    action_kind: "administrative",
    reason: "exceptional_circumstances",
    edi_code: "EX-EXCEPTIONAL CIRCUMSTANCES", 
    market_kind: "shop", 
    effective_on_kinds: ["first_of_month"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: false, 
    ordinal_position: 70,
    tool_tip: "Enroll due to an inadvertent or erroneous enrollment or another exceptional circumstance"
  )

QualifyingLifeEventKind.create!(
    title: "contract_violation", 
    action_kind: "administrative",
    reason: "contract_violation",
    edi_code: "33-CONTRACT VIOLATION", 
    market_kind: "shop", 
    effective_on_kinds: ["first_of_month"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30, 
    is_self_attested: false, 
    ordinal_position: 75,
    tool_tip: "Enroll due to contract violation"
  )

puts "::: QualifyingLifeEventKinds Complete :::"
puts "*"*80
