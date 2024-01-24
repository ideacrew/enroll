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
    effective_on_kinds: ["date_of_event"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 60,
    is_self_attested: true,
    is_visible: true,
    date_options_available: false,
    ordinal_position: 1
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
    effective_on_kinds: ["date_of_event"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 60,
    is_self_attested: true,
    is_visible: true,
    date_options_available: false
  )
end

QualifyingLifeEventKind.find_or_create_by(
  title: "Got married"
).tap do |qlek|
  qlek.update_attributes(
    tool_tip: "Someone in the household got married",
    action_kind: "add_member",
    market_kind: "individual",
    event_kind_label: "Date of marriage",
    ordinal_position: 5,
    reason: "marriage",
    edi_code: "32-MARRIAGE",
    effective_on_kinds: ["first_of_next_month"],
    pre_event_sep_in_days: 0,
    post_event_sep_in_days: 60,
    is_self_attested: true,
    is_visible: true,
    date_options_available: false,
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
    ordinal_position: 6,
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
    ordinal_position: 3,
    reason: "lost_access_to_mec",
    edi_code: "33-LOST ACCESS TO MEC",
    effective_on_kinds: ["first_of_next_month"],
    pre_event_sep_in_days: 60,
    post_event_sep_in_days: 60, # "60 days before loss of coverage and 60 days after",
    is_self_attested: true,
    is_visible: true,
    date_options_available: false
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
    ordinal_position: 4,
    reason: "moved",
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
  title: "Enrollment error by CoverME”"
).tap do |qlek|
  qlek.update_attributes(
    tool_tip: "Someone is not enrolled or enrolled in the wrong plan due to an error by CoverME",
    action_kind: "add_member",
    market_kind: "individual",
    ordinal_position: 23,
    reason: "enrollment_error_hbx",
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
    ordinal_position: 25,
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
    ordinal_position: 8,
    reason: "native_american",
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
  title: "Starting or ending AmeriCorps service").tap do |qlek|
  qlek.update_attributes(
  tool_tip: "Someone is beginning or ending service with AmeriCorps State and National, VISTA, or NCCC",
  action_kind: "add_member",
  market_kind: "individual",
  event_kind_label: "Date service begins or ends",
  ordinal_position: 16,
  reason: "americorps",
  edi_code: " ",
  effective_on_kinds: ["first_of_next_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: false,
  is_visible: true,
  date_options_available: false
  )
end

QualifyingLifeEventKind.find_or_create_by(
  title: "Court or child support order").tap do |qlek|
  qlek.update_attributes(
  tool_tip: "Someone needs to provide coverage due to a court or child support order",
  action_kind: "add_member",
  market_kind: "individual",
  event_kind_label: "Date that court orders that coverage starts",
  ordinal_position: 18,
  reason: "court_order",
  edi_code: " ",
  effective_on_kinds: ["date_of_event"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: false,
  is_visible: true,
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
  ordinal_position: 10,
  reason: "citizenship_immigration_change",
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
  ordinal_position: 15,
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
  title: "Enrollment error by a broker or enrollment assister").tap do |qlek|
  qlek.update_attributes(
  tool_tip: "Someone is not enrolled or enrolled in the wrong plan due to an error by a broker or enrollment assister",
  action_kind: "add_member",
  market_kind: "individual",
  ordinal_position: 22,
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

# Expired as of June 2021
# QualifyingLifeEventKind.find_or_create_by(
#  title: "Found ineligible for employer-sponsored insurance after open enrollment ended").tap do |qlek|
#  qlek.update_attributes(
#    tool_tip: "Someone did not enroll in individual or family coverage because employer was applying to provide coverage, and found out after open enrollment that employer coverage was denied",
#    action_kind: "add_member",
#    market_kind: "individual",
#    ordinal_position: 20,
#    reason: "eligibility_change_employer_ineligible",
#    edi_code: " ",
#    effective_on_kinds: ["first_of_next_month"],
#    pre_event_sep_in_days: 0,
#    post_event_sep_in_days: 60,
#    is_self_attested: false,
#    is_visible: false,
#    date_options_available: true
#  )
# end

# TODO: FIgure out what first of next month plan selection is
QualifyingLifeEventKind.find_or_create_by(
  title: "Domestic abuse or spousal abandonment"
).tap do |qlek|
  qlek.update_attributes(
  tool_tip: "Someone needs health coverage because they were a victim of domestic abuse or spousal abandonment",
  action_kind: "add_member",
  market_kind: "individual",
  event_kind_label: "Date you left the household",
  ordinal_position: 26,
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
  ordinal_position: 21,
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
  ordinal_position: 28,
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
  ordinal_position: 9,
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
  ordinal_position: 11,
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
  ordinal_position: 12,
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
  title: "Exceptional circumstances"
).tap do |qlek|
  qlek.update_attributes(
  tool_tip: "An exceptional circumstance prevented someone from enrolling during open enrollment or a special enrollment period",
  event_kind_label: "Date of event",
  action_kind: "transition_member",
  market_kind: "individual",
  ordinal_position: 27,
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
  ordinal_position: 24,
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
  ordinal_position: 13,
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
  title: "Denied Medicaid or CHIP after enrollment period"
).tap do |qlek|
  qlek.update_attributes(
  tool_tip: "A marketplace enrollee is found newly eligible or ineligible for advance premium tax credits, or someone who is not enrolled has a decrease in income that makes them eligible",
  event_kind_label: "Date of denial",
  action_kind: "transition_member",
  market_kind: "individual",
  ordinal_position: 19,
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
  ordinal_position: 7,
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
  title: "Change in eligibility for cost-sharing reductions"
).tap do |qlek|
  qlek.update_attributes(
  tool_tip: "A marketplace enrollee is found newly eligible or ineligible for cost-sharing reductions",
  event_kind_label: "Today's date",
  action_kind: "transition_member",
  market_kind: "individual",
  ordinal_position: 14,
  reason: "csr_eligibility_change",
  edi_code: "",
  effective_on_kinds: ["first_of_next_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: false,
  is_visible: true,
  date_options_available: false
  )
end

# COVID 19: Expired as of June 2021
# QualifyingLifeEventKind.find_or_create_by(
#  title: "Covid-19"
#).tap do |qlek|
#  qlek.update_attributes(
#    tool_tip: "Someone is uninsured and needs coverage due to the Covid-19 pandemic",
#    event_kind_label: "Today's date",
#    action_kind: "transition_member",
#    market_kind: "individual",
#    effective_on_kinds: ["first_of_this_month", "fixed_first_of_next_month"],
#    reason: "covid",
#    edi_code: nil,
#    pre_event_sep_in_days: 0,
#    is_self_attested: true,
#    date_options_available: false,
#    post_event_sep_in_days: 60,
#    ordinal_position: 29,
#    is_visible: true
#  )
#end

QualifyingLifeEventKind.find_or_create_by(title: "COBRA subsidy expiring").tap do |qlek|
  qlek.update_attributes(
    event_kind_label: "Last day of subsidized premiums",
    title: "COBRA subsidy expiring",
    effective_on_kinds: ["first_of_next_month_plan_selection"],
    reason: "cobra_subsidy_expiring",
    market_kind: "individual",
    tool_tip: "Government or employer subsidies for someone's COBRA premiums are ending",
    pre_event_sep_in_days: 60,
    is_self_attested: true,
    date_options_available: false,
    post_event_sep_in_days: 60,
    ordinal_position: 26,
    is_active: true,qle_event_date_kind: :qle_on,
    is_visible: true,
    termination_on_kinds: []
  )
end

QualifyingLifeEventKind.find_or_create_by(title: "Late notice of qualifying event").tap do |qlek|
  qlek.update_attributes(
    event_kind_label: "Date of notice",
    action_kind: nil,
    title: "Late notice of qualifying event",
    effective_on_kinds: ["first_of_next_month_plan_selection"],
    reason: "late_notice",
    market_kind: "individual",
    tool_tip: "Someone didn't find out about a qualifying event (for example, that other coverage was ending) until after it was too late to enroll",
    pre_event_sep_in_days: 0,
    is_self_attested: false,
    date_options_available: true,
    post_event_sep_in_days: 60,
    ordinal_position: 27,
    is_active: true,
    qle_event_date_kind: :qle_on,
    is_visible: true,
    termination_on_kinds: [],
  )
end

puts "::: IVL QualifyingLifeEventKinds Complete :::"
puts "*" * 80
