puts "*" * 80
puts "::: Beginning creating IVL QualifyingLifeEventKinds :::"

QualifyingLifeEventKind.find_or_create_by(
  title: "Had a baby"
).tap do |qlek|
  qlek.update_attributes(
    tool_tip: "Someone in the household had a baby",
    action_kind: "add_member",
    market_kind: "individual",
    event_kind_label: "Date of birth",
    reason: "birth",
    edi_code: "02-BIRTH",
    ordinal_position: 10,
    effective_on_kinds: ["date_of_event", "fixed_first_of_next_month"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 60,
    is_self_attested: true,
    is_visible: true,
    date_options_available: false
  )
end

QualifyingLifeEventKind.find_or_create_by(
  title: "Adopted a child"
).tap do |qlek|
  qlek.update_attributes(
    tool_tip: "A child has been adopted, placed for adoption, or placed in foster care",
    action_kind: "add_member",
    market_kind: "individual",
    event_kind_label: "Date of adoption",
    ordinal_position: 20,
    reason: "adoption",
    edi_code: "05-ADOPTION",
    effective_on_kinds: ["date_of_event", "fixed_first_of_next_month"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 60,
    is_self_attested: true,
    is_visible: true,
    date_options_available: false
  )
end

QualifyingLifeEventKind.find_or_create_by(
  title: "Got Married"
).tap do |qlek|
  qlek.update_attributes(
    tool_tip: "Someone in the household got married",
    action_kind: "add_member",
    market_kind: "individual",
    event_kind_label: "Date of marriage",
    ordinal_position: 30,
    reason: "marriage",
    edi_code: "32-MARRIAGE",
    effective_on_kinds: ["first_of_next_month"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 60,
    is_self_attested: true,
    is_visible: true,
    date_options_available: false
  )
end

QualifyingLifeEventKind.find_or_create_by(
  title: "Divorce or legal seperation"
).tap do |qlek|
  qlek.update_attributes(
    tool_tip: "A marketplace enrollee loses a dependent or is no longer considered a dependent due to divorce of legal separation",
    action_kind: "drop_member",
    market_kind: "individual",
    event_kind_label: "Date of divorce or legal seperation",
    ordinal_position: 45,
    reason: "divorce",
    edi_code: "01-DIVORCE",
    effective_on_kinds: ["first_of_next_month"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 60,
    is_self_attested: true,
    is_visible: true,
    date_options_available: false
  )
end

QualifyingLifeEventKind.find_or_create_by(
  title: "Lost or will soon lose other health insurance"
).tap do |qlek|
  qlek.update_attributes(
    tool_tip: "Someone in the household is losing other health insurance involuntarily",
    action_kind: "add_benefit",
    event_kind_label: "Coverage end date",
    market_kind: "individual",
    ordinal_position: 50,
    reason: "lost_access_to_mec",
    edi_code: "33-LOST ACCESS TO MEC",
    effective_on_kinds: ["first_of_next_month"],
    pre_event_sep_in_days: 60,
    post_event_sep_in_days: 60, # "60 days before loss of coverage and 60 days after",
    is_self_attested: true,
    is_visible: true,
    date_options_available: false
    # start_of_sep: "60 days before loss of MEC",
    # coverage_effective_date: "If before loss of coverage: First day of the month after MEC will end. If after loss of MEC: First day of the month following plan selection (not following 15th of month rule)")
  )
end

QualifyingLifeEventKind.find_or_create_by(
  title: "Moved or about to move"
).tap do |qlek|
  qlek.update_attributes(
    tool_tip: "Someone made or is about to make a permanent move",
    action_kind: "add_benefit",
    market_kind: "individual",
    event_kind_label: "Date of move",
    ordinal_position: 60,
    reason: "relocate",
    edi_code: "43-CHANGE OF LOCATION",
    effective_on_kinds: ["first_of_next_month"],
    pre_event_sep_in_days: 60,
    post_event_sep_in_days: 60,
    is_self_attested: true,
    is_visible: true,
    date_options_available: false
  )
end

QualifyingLifeEventKind.find_or_create_by(
  title: "Enrollment error caused by Cover ME"
).tap do |qlek|
  qlek.update_attributes(
    tool_tip: "Someone is not enrolled or enrolled in the wrong plan due to an error by Cover ME",
    action_kind: "add_member",
    market_kind: "individual",
    ordinal_position: 70,
    reason: "enrollment_error_or_misconduct_hbx",
    edi_code: " ",
    effective_on_kinds: ["first_of_next_month", "first_of_month"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 60,
    is_self_attested: false,
    is_visible: true,
    date_options_available: true
  )
end

QualifyingLifeEventKind.find_or_create_by(
  title: "Health plan contract violation"
).tap do |qlek|
  qlek.update_attributes(
    tool_tip: " ",
    action_kind: "add_member",
    market_kind: "individual",
    ordinal_position: 90,
    reason: "contract_violation",
    edi_code: "33-CONTRACT VIOLATION",
    effective_on_kinds: ["first_of_month"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 60,
    is_self_attested: false,
    is_visible: false,
    date_options_available: true
  )
end

QualifyingLifeEventKind.find_or_create_by(
  title: "Native American or Alaskan Native"
).tap do |qlek|
  qlek.update_attributes(
    tool_tip: "Someone is a member of an American Indian or Alaska Native tribe",
    action_kind: "add_member",
    market_kind: "individual",
    event_kind_label: "Today's date",
    ordinal_position: 100,
    reason: "qualified_native_american",
    edi_code: " ",
    effective_on_kinds: ["first_of_month"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 30,
    is_self_attested: false,
    is_visible: false,
    date_options_available: false
  )
end


QualifyingLifeEventKind.find_or_create_by(
  title: "Beginning or ending AmeriCorps service").tap do |qlek|
  qlek.update_attributes(
  tool_tip: "Someone is beginning or ending service with AmeriCorps State and National, VISTA, or NCCC",
  action_kind: "add_member",
  market_kind: "individual",
  event_kind_label: "Date service begins or ends",
  ordinal_position: 100,
  reason: "exceptional_circumstances_civic_service",
  edi_code: " ",
  effective_on_kinds: ["first_of_next_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: false,
  is_visible: true,
  date_options_available: false
    # start_of_sep: "Date person begins or ends service in one of the three programs",
    # coverage_effective_date: "Regular effective date")
  )
end

QualifyingLifeEventKind.find_or_create_by(
  title: "Court or child support order").tap do |qlek|
  qlek.update_attributes(
  tool_tip: "Someone needs to provide coverage due to a court or child support order",
  action_kind: "add_member",
  market_kind: "individual",
  event_kind_label: "Date that court orders that coverage starts",
  ordinal_position: 100,
  reason: "court_order",
  edi_code: " ",
  effective_on_kinds: ["date_of_event"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: false,
  is_visible: false,
  date_options_available: false
  )
end

QualifyingLifeEventKind.find_or_create_by(
  title: "Gained citizenship or lawful presence").tap do |qlek|
  qlek.update_attributes(
  tool_tip: "Someone is newly eligible for marketplace coverage due to gaining citizenship or an eligible immigration status",
  action_kind: "add_benefit",
  market_kind: "individual",
  event_kind_label: "Date of status change",
  ordinal_position: 100,
  reason: "eligibility_change_immigration_status",
  edi_code: " ",
  effective_on_kinds: ["first_of_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: false,
  is_visible: false,
  date_options_available: false
  )
end

# TODO: figure out what the first of next month plan selection means
QualifyingLifeEventKind.find_or_create_by(
  title: "Released from incarceration").tap do |qlek|
  qlek.update_attributes(
  tool_tip: "Someone is newly eligible for marketplace coverage because they were released from incarceration",
  action_kind: "add_benefit",
  market_kind: "individual",
  event_kind_label: "Release date",
  ordinal_position: 100,
  reason: "incarceration_release",
  edi_code: " ",
  effective_on_kinds: ["first_of_next_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: false,
  is_visible: false,
  date_options_available: false
  )
end

QualifyingLifeEventKind.find_or_create_by(
  title: "Enrollment error caused by my health insurance company"
).tap do |qlek|
  qlek.update_attributes(
  tool_tip: "You are not enrolled or are enrolled in the wrong plan because of an error made by your insurance company",
  action_kind: "add_member",
  market_kind: "individual",
  ordinal_position: 100,
  reason: "enrollment_error_or_misconduct_issuer",
  edi_code: " ",
  effective_on_kinds: ["first_of_next_month", "first_of_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: false,
  is_visible: false,
  date_options_available: false
    # start_of_sep: "Date approved by HBX",
    # coverage_effective_date: "Regular effective date")
  )
end

QualifyingLifeEventKind.find_or_create_by(
  title: "Enrollment error by a broker or enrollment assister").tap do |qlek|
  qlek.update_attributes(
  tool_tip: "Someone is not enrolled or enrolled in the wrong plan due to an error by a broker or enrollment assister",
  action_kind: "add_member",
  market_kind: "individual",
  ordinal_position: 100,
  reason: "enrollment_error_assister_broker",
  edi_code: " ",
  effective_on_kinds: ["first_of_next_month", "first_of_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: false,
  is_visible: false,
  date_options_available: true
  )
end

QualifyingLifeEventKind.find_or_create_by(
  title: "Found ineligible for employer-sponsored insurance after open enrollment ended").tap do |qlek|
  qlek.update_attributes(
    tool_tip: "Someone did not enroll in individual or family coverage because employer was applying to provide coverage, and found out after open enrollment that employer coverage was denied",
    action_kind: "add_member",
    market_kind: "individual",
    ordinal_position: 100,
    reason: "eligibility_change_employer_ineligible",
    edi_code: " ",
    effective_on_kinds: ["first_of_next_month"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 60,
    is_self_attested: false,
    is_visible: false,
    date_options_available: true
  )
end

# TODO: FIgure out what first of next month plan selection is
QualifyingLifeEventKind.find_or_create_by(
  title: "Domestic abuse or spousal abandonment"
).tap do |qlek|
  qlek.update_attributes(
  tool_tip: "Someone needs health coverage because they were a victim of domestic abuse or spousal abandonment",
  action_kind: "add_member",
  market_kind: "individual",
  event_kind_label: "Date you left the household",
  ordinal_position: 100,
  reason: "domestic_abuse",
  edi_code: " ",
  effective_on_kinds: ["first_of_next_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: false,
  is_visible: true,
  date_options_available: true
  )
end

QualifyingLifeEventKind.find_or_create_by(
  title: "Employer did not pay premiums on time"
).tap do |qlek|
  qlek.update_attributes(
  tool_tip: "Someone's employer coverage is ending due to employer’s failure to make payments",
  action_kind: "add_member",
  market_kind: "individual",
  event_kind_label: "Date of notice of plan termination",
  ordinal_position: 100,
  reason: "employer_unpaid_premium",
  edi_code: " ",
  effective_on_kinds: ["first_of_next_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: false,
  is_visible: false,
  date_options_available: true
    # start_of_sep: "Based on circumstances as determined by HBX Date of loss of coverage",
    # coverage_effective_date: "As determined by HBX, with the intent of preventing gaps in health coverage")
  )
end


QualifyingLifeEventKind.find_or_create_by(
  title: "Provided documents proving eligibility"
).tap do |qlek|
  qlek.update_attributes(
  tool_tip: " ",
  action_kind: "transition_member",
  market_kind: "individual",
  ordinal_position: 120,
  reason: "eligibility_documents",
  edi_code: " ",
  effective_on_kinds: ["first_of_next_month", "first_of_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: false,
  is_visible: false,
  date_options_available: false
  )
end

QualifyingLifeEventKind.find_or_create_by(
  title: "Pregnancy"
).tap do |qlek|
  qlek.update_attributes(
  tool_tip: "Someone needs to enroll because they are pregnant",
  event_kind_label: "Date provider confirmed pregnancy",
  action_kind: "transition_member",
  market_kind: "individual",
  ordinal_position: 120,
  reason: "pregnancy",
  edi_code: "",
  effective_on_kinds: ["first_of_next_month", "first_of_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: false,
  is_visible: true,
  date_options_available: false
  )
end

# TODO: Has first of next month coinciding - what does that mean
QualifyingLifeEventKind.find_or_create_by(
  title: "New offer of an HRA at the beginning of the plan year"
).tap do |qlek|
  qlek.update_attributes(
  tool_tip: "Someone has a new offer of a Health Reimbursement Arrangement from an employer",
  event_kind_label: "Date provider confirmed pregnancy",
  action_kind: "transition_member",
  market_kind: "individual",
  ordinal_position: 120,
  reason: "new_hra_plan_year",
  edi_code: "",
  effective_on_kinds: ["first_of_next_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: false,
  is_visible: true,
  date_options_available: false
  )
end

# TODO: Has first of next month coinciding - what does that mean
QualifyingLifeEventKind.find_or_create_by(
  title: "New offer of an HRA during the plan year"
).tap do |qlek|
  qlek.update_attributes(
  tool_tip: "Someone has a new offer of a Health Reimbursement Arrangement starting during the plan year (for example, when newly hired)",
  event_kind_label: "Date provider confirmed pregnancy",
  action_kind: "transition_member",
  market_kind: "individual",
  ordinal_position: 120,
  reason: "hra_midyear",
  edi_code: "",
  effective_on_kinds: ["first_of_next_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: false,
  is_visible: true,
  date_options_available: false
  )
end

# TODO: Says first_of_next_month plan selection need to figure that out
QualifyingLifeEventKind.find_or_create_by(
  title: "Exceptional circumstance"
).tap do |qlek|
  qlek.update_attributes(
  tool_tip: "An exceptional circumstance prevented someone from enrolling during open enrollment or a special enrollment period",
  event_kind_label: "Date of event",
  action_kind: "transition_member",
  market_kind: "individual",
  ordinal_position: 120,
  reason: "exceptional_circumstance",
  edi_code: "",
  effective_on_kinds: ["first_of_next_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: false,
  is_visible: true,
  date_options_available: true
  )
end

# TODO: Says first_of_next_month plan selection need to figure that out
QualifyingLifeEventKind.find_or_create_by(
  title: "Plan error"
).tap do |qlek|
  qlek.update_attributes(
  tool_tip: "A material error related to plan benefits, service area, or premium influenced someone's health plan selection",
  event_kind_label: "Date error was discoovered",
  action_kind: "transition_member",
  market_kind: "individual",
  ordinal_position: 120,
  reason: "enrollment_error_carrier",
  edi_code: "",
  effective_on_kinds: ["first_of_next_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: false,
  is_visible: true,
  date_options_available: true
  )
end

# TODO: Says first of next month plan selection
QualifyingLifeEventKind.find_or_create_by(
  title: "Newly eligible or ineligible for APTC"
).tap do |qlek|
  qlek.update_attributes(
  tool_tip: "A marketplace enrollee is found newly eligible or ineligible for advance premium tax credits, or someone who is not enrolled has a decrease in income that makes them eligible",
  event_kind_label: "Date error was discoovered",
  action_kind: "transition_member",
  market_kind: "individual",
  ordinal_position: 120,
  reason: "income_change",
  edi_code: "",
  effective_on_kinds: ["first_of_next_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: false,
  is_visible: true,
  date_options_available: false
  )
end

# TODO: Says first of next month plan selection
QualifyingLifeEventKind.find_or_create_by(
  title: "Denied MaineCare or CubCare after enrollment period"
).tap do |qlek|
  qlek.update_attributes(
  tool_tip: "A marketplace enrollee is found newly eligible or ineligible for advance premium tax credits, or someone who is not enrolled has a decrease in income that makes them eligible",
  event_kind_label: "Date of denial",
  action_kind: "transition_member",
  market_kind: "individual",
  ordinal_position: 120,
  reason: "medicaid_ineligible",
  edi_code: "",
  effective_on_kinds: ["first_of_next_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: false,
  is_visible: true,
  date_options_available: true
  )
end

QualifyingLifeEventKind.find_or_create_by(
  title: "Death"
).tap do |qlek|
  qlek.update_attributes(
  tool_tip: "A marketplace enrollee loses a dependent or is no longer considered a dependent due to a death",
  event_kind_label: "Date of death",
  action_kind: "transition_member",
  market_kind: "individual",
  ordinal_position: 120,
  reason: "medicaid_ineligible",
  edi_code: "",
  effective_on_kinds: ["first_of_next_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: false,
  is_visible: true,
  date_options_available: true
  )
end


puts "::: IVL QualifyingLifeEventKinds Complete :::"
puts "*" * 80
