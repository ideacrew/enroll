QualifyingLifeEventKind.create!(
  title: "I've had a baby",
  tool_tip: "Household adds a member due to marriage, birth, adoption, placement for adoption, or placement in foster care",
  action_kind: "add_member",
  market_kind: "individual",
  event_kind_label: "Date of birth",
  reason: " ",
  edi_code: "02-BIRTH", 
  ordinal_position: 10,
  effective_on_kinds: ["date_of_event", "fixed_first_of_next_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: true,
    # coverage_effective_date: "Date of birth, adoption, placement for adoption, placement in foster care, or marriage.  For marriage: First day of the month following plan selection (not following 15th of month rule); this applies to all members of household")
  )

QualifyingLifeEventKind.create!(
  title: "I've adopted a child",
  tool_tip: "A child has been adopted, placed for adoption, or placed in foster care",
  action_kind: "add_member",
  market_kind: "individual",
  event_kind_label: "Date of adoption",
  ordinal_position: 11,
  reason: " ",
  edi_code: "05-ADOPTION", 
  effective_on_kinds: ["date_of_event", "fixed_first_of_next_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: true,
    # coverage_effective_date: "Date of birth, adoption, placement for adoption, placement in foster care, or marriage.  For marriage: First day of the month following plan selection (not following 15th of month rule); this applies to all members of household")
  )

QualifyingLifeEventKind.create!(
  title: "I'm losing other health insurance",
  tool_tip: "Someone in the household is losing other health insurance involuntarily",
  action_kind: "add_benefit",
  event_kind_label: "Coverage end date",
  market_kind: "individual",
  ordinal_position: 12,
  reason: "lost_access_to_mec",
  edi_code: "33-LOST ACCESS TO MEC", 
  effective_on_kinds: ["first_of_month"],
  pre_event_sep_in_days: 60,
  post_event_sep_in_days: 60, # "60 days before loss of coverage and 60 days after",
  is_self_attested: true,
    # start_of_sep: "60 days before loss of MEC",
    # coverage_effective_date: "If before loss of coverage: First day of the month after MEC will end. If after loss of MEC: First day of the month following plan selection (not following 15th of month rule)")
  )

QualifyingLifeEventKind.create!(
  title: "I've married",
  tool_tip: " ",
  action_kind: "add_member",
  market_kind: "individual",
  event_kind_label: "Date of marriage",
  ordinal_position: 13,
  reason: " ",
  edi_code: "32-MARRIAGE", 
  effective_on_kinds: ["first_of_next_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: true,
    # coverage_effective_date: "Date of birth, adoption, placement for adoption, placement in foster care, or marriage.  For marriage: First day of the month following plan selection (not following 15th of month rule); this applies to all members of household")
  )

QualifyingLifeEventKind.create!(
  title: "Losing Employer-Subsidized Insurance because employee is going on Medicare",
  tool_tip: "A dependent is losing access to ESI coverage because the employee is enrolling in Medicare",
  action_kind: "add_benefit",
  event_kind_label: "Last day of coverage",
  market_kind: "individual",
  ordinal_position: 14,
  reason: "employee_gaining_medicare",
  edi_code: "33-LOST ACCESS TO MEC", 
  effective_on_kinds: ["first_of_next_month"],
  pre_event_sep_in_days: 60,
  post_event_sep_in_days: 60, # "60 days before loss of coverage and 60 days after",
  is_self_attested: true,
    # event_kind_label: "coverage end date",
    # start_of_sep: "60 days before loss of MEC",
    # coverage_effective_date: "If before loss of coverage: First day of the month after MEC will end. If after loss of MEC: First day of the month following plan selection (not following 15th of month rule)")
  )

QualifyingLifeEventKind.create!(
  title: "I've entered into a legal domestic partnership",
  tool_tip: "Entering a domestic partnership as permitted or recognized by the District of Columbia",
  action_kind: "add_member",
  market_kind: "individual",
  event_kind_label: "Date of domestic partnership",
  ordinal_position: 100,
  reason: " ",
  edi_code: "33-ENTERING DOMESTIC PARTNERSHIP", 
  effective_on_kinds: ["first_of_next_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: true,
    # start_of_sep: "Date partnership entered into",
    # coverage_effective_date: "First day of the month following plan selection (not following 15th of month rule); this applies to all members of household")
  )

QualifyingLifeEventKind.create!(
  title: "I've divorced or ended domestic partnership",
  tool_tip: "Someone has divorced, ended a domestic partnership, or legally separated",
  action_kind: "drop_member",
  market_kind: "individual",
  event_kind_label: "Divorce or partnership end date",
  ordinal_position: 100,
  reason: " ",
  edi_code: "01-DIVORCE", 
  effective_on_kinds: ["first_of_next_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: true,
    # start_of_sep: "Date of divorce, legal separation, partnership termination",
    # coverage_effective_date: "First day of the month following plan selection (not following 15th of month rule); this applies to all members of household")
  )

QualifyingLifeEventKind.create!(
  title: "I'm moving to the District of Columbia",
  tool_tip: " ",
  action_kind: "add_benefit",
  market_kind: "individual",
  event_kind_label: "Date of move",
  ordinal_position: 100,
  reason: "move_to_state",
  edi_code: "43-CHANGE OF LOCATION", 
  effective_on_kinds: ["first_of_next_month"],
  pre_event_sep_in_days: 60,
  post_event_sep_in_days: 60,
  is_self_attested: true,
    # start_of_sep: "Date of move    ",
    # coverage_effective_date: "Regular effective date")
  )


QualifyingLifeEventKind.create!(
  title: "Change in APTC/CSR",
  tool_tip: "Consumer has a change in circumstances that makes him or her newly eligible or ineligible for APTC changes eligibility for CSR. Only applies to those already enrolled in a QHP.",
  action_kind: "change_benefit",
  market_kind: "individual",
  event_kind_label: "Date of change",
  ordinal_position: 100,
  reason: " ",
  edi_code: " ",
  effective_on_kinds: ["first_of_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: false,
    # start_of_sep: "Date of eligibility redetermination (NOTE: this is not necessarily the date the customer reported the change)",
    # coverage_effective_date: "Regular effective date")
  )

QualifyingLifeEventKind.create!(
  title: "My immigration status has changed",
  tool_tip: "Someone gains a status that makes them newly eligible to enroll in coverage through DC Health Link",
  action_kind: "add_benefit",
  market_kind: "individual",
  event_kind_label: "Date of change",
  ordinal_position: 100,
  reason: " ",
  edi_code: " ",
  effective_on_kinds: ["first_of_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: false,
    # start_of_sep: "Date change was verified (NOTE: this is not necessarily the date the customer reported the change)",
    # coverage_effective_date: "Regular effective date")
  )

QualifyingLifeEventKind.create!(
  title: "I'm a Native American",
  tool_tip: " ",
  action_kind: "add_member",
  market_kind: "individual",
  ordinal_position: 100,
  reason: " ",
  edi_code: " ",
  effective_on_kinds: ["first_of_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 30,
  is_self_attested: false,
    # start_of_sep: "Date approved by HBX",    
    # coverage_effective_date: "Regular effective date")
  )

QualifyingLifeEventKind.create!(
  title: "Problem with my enrollment caused by DC Health Link",
  tool_tip: "You are not enrolled or are enrolled in the wrong plan because of an error made by DC Health Link or the Department of Health and Human Services",
  action_kind: "add_member",
  market_kind: "individual",
  ordinal_position: 100,
  reason: " ",
  edi_code: " ",
  effective_on_kinds: ["first_of_next_month", "first_of_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: false,
    # start_of_sep: "Date approved by HBX",    
    # coverage_effective_date: "Regular effective date")
  )

QualifyingLifeEventKind.create!(
  title: "Problem with my enrollment caused by my health insurance company",
  tool_tip: "You are not enrolled or are enrolled in the wrong plan because of an error made by your insurance company",
  action_kind: "add_member",
  market_kind: "individual",
  ordinal_position: 100,
  reason: " ",
  edi_code: " ",
  effective_on_kinds: ["first_of_next_month", "first_of_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: false,
    # start_of_sep: "Date approved by HBX",    
    # coverage_effective_date: "Regular effective date")
  )

QualifyingLifeEventKind.create!(
  title: "Problem with my enrollment caused by someone providing me with enrollment assistance",
  tool_tip: "You are not enrolled or are enrolled in the wrong plan because of an error made by a broker, in-person assister, or another expert trained by DC Health Link",
  action_kind: "add_member",
  market_kind: "individual",
  ordinal_position: 100,
  reason: " ",
  edi_code: " ",
  effective_on_kinds: ["first_of_next_month", "first_of_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: false,
    # start_of_sep: "Date approved by HBX",       
    # coverage_effective_date: "Regular effective date")
  )

QualifyingLifeEventKind.create!(
  title: "My health plan violated its contract",
  tool_tip: " ",
  action_kind: "add_member",
  market_kind: "individual",
  ordinal_position: 100,
  reason: " ",
  edi_code: "33-CONTRACT VIOLATION", 
  effective_on_kinds: ["first_of_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: false,
    # start_of_sep: "Date approved by HBX",       
    # coverage_effective_date: "Regular effective date")
  )

QualifyingLifeEventKind.create!(
  title: "I applied during open enrollment but got my Medicaid denial after open enrollment ended",
  tool_tip: "Consumer had pending Medicaid eligibility at the end of open enrollment, but was found ineligible after open enrollment.",
  action_kind: "add_member",
  market_kind: "individual",
  ordinal_position: 100,
  reason: " ",
  edi_code: " ",
  effective_on_kinds: ["first_of_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: false,
    # start_of_sep: "Date consumer received notice of Medicaid ineligibility",
    # coverage_effective_date: "Regular effective date")
  )

QualifyingLifeEventKind.create!(
  title: "My employer applied for small business coverage during open enrollment but was denied after open enrollment ended",
  tool_tip: "Consumer did not enroll in a QHP because consumer’s employer was applying to provide coverage through SHOP during open enrollment. Consumer’s employer was found ineligible to participate in SHOP after the end of open enrollment",
  action_kind: "add_member",
  market_kind: "individual",
  ordinal_position: 100,
  reason: " ",
  edi_code: " ",
  effective_on_kinds: ["first_of_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: false,
    # start_of_sep: "Date consumer received notice of SHOP ineligibility    ",
    # coverage_effective_date: "Regular effective date")
  )

QualifyingLifeEventKind.create!(
  title: "A natural disaster prevented me from enrolling",
  tool_tip: "A natural disaster during open enrollment or a special enrollment period prevented me from enrolling",
  action_kind: "add_member",
  market_kind: "individual",
  ordinal_position: 100,
  reason: " ",
  edi_code: " ",
  effective_on_kinds: ["first_of_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: false,
    # start_of_sep: "Day of disaster (or last day of multi-day disaster)",
    # coverage_effective_date: "Regular effective date")
  )

QualifyingLifeEventKind.create!(
  title: "A medical emergency prevented me from enrolling",
  tool_tip: "A serious medical emergency during open enrollment or a special enrollment period prevented me from enrolling",
  action_kind: "add_member",
  market_kind: "individual",
  ordinal_position: 100,
  reason: " ",
  edi_code: " ",
  effective_on_kinds: ["first_of_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: false,
    # start_of_sep: "Date approved by HBX",       
    # coverage_effective_date: "Regular effective date")
  )

QualifyingLifeEventKind.create!(
  title: "I was unable to enroll because of a system outage",
  tool_tip: "A DC Health Link outage or outage in federal and local data sources close to an open enrollment or special enrollment period deadline prevented me from enrolling",
  action_kind: "add_member",
  market_kind: "individual",
  ordinal_position: 100,
  reason: " ",
  edi_code: " ",
  effective_on_kinds: ["first_of_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: false,
    # start_of_sep: "Day of outage",
    # coverage_effective_date: "Regular effective date")
  )

QualifyingLifeEventKind.create!(
  title: "I have experienced domestic abuse",
  tool_tip: "A person is leaving an abusive spouse or domestic partner",
  action_kind: "add_member",
  market_kind: "individual",
  event_kind_label: "Date you left the household",
  ordinal_position: 100,
  reason: " ",
  edi_code: " ",
  effective_on_kinds: ["first_of_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: false,
    # start_of_sep: "Date person leaves spouse or domestic partner",
    # coverage_effective_date: "Regular effective date")
  )

QualifyingLifeEventKind.create!(
  title: "I lost eligibility for a hardship exemption",
  tool_tip: "I had a certificate of exemption from the individual mandate for this year but have lost eligibility for that exemption",
  action_kind: "add_member",
  market_kind: "individual",
  event_kind_label: "Date hardship exemption ends",
  ordinal_position: 100,
  reason: " ",
  edi_code: " ",
  effective_on_kinds: ["first_of_month"],
  pre_event_sep_in_days: 30,
  post_event_sep_in_days: 30,
  is_self_attested: false,
    # start_of_sep: "30 days prior to date of ineligibility for exemption",
    # coverage_effective_date: "Regular effective date")
  )

QualifyingLifeEventKind.create!(
  title: "I am beginning or ending service with AmeriCorps State and National, VISTA, or NCCC",
  tool_tip: "An individual is a member of AmeriCorps State and National, VISTA, or NCCC.",
  action_kind: "add_member",
  market_kind: "individual",
  event_kind_label: "Date service begins or ends",
  ordinal_position: 100,
  reason: " ",
  edi_code: " ",
  effective_on_kinds: ["first_of_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: true,
    # start_of_sep: "Date person begins or ends service in one of the three programs",
    # coverage_effective_date: "Regular effective date")
  )

QualifyingLifeEventKind.create!(
  title: "I’ve been ordered by a court to provide coverage for someone",
  tool_tip: "I have a medical insurance coverage order from a court",
  action_kind: "add_member",
  market_kind: "individual",
  event_kind_label: "Date that court orders that coverage starts",
  ordinal_position: 100,
  reason: " ",
  edi_code: " ",
  effective_on_kinds: ["exact_date"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: true,
    # start_of_sep: "Date of the court order",
    # coverage_effective_date: "Regular effective date")
  )

QualifyingLifeEventKind.create!(
  title: "My employer did not pay my premiums on time",
  tool_tip: "Employer coverage is ending due to employer’s failure to make payments",
  action_kind: "add_member",
  market_kind: "individual",
  event_kind_label: "Date of notice of plan termination",
  ordinal_position: 100,
  reason: " ",
  edi_code: " ",
  effective_on_kinds: ["first_of_next_month"],
  pre_event_sep_in_days: 60,
  post_event_sep_in_days: 60,
  is_self_attested: true,
    # start_of_sep: "Based on circumstances as determined by HBX Date of loss of coverage",
    # coverage_effective_date: "As determined by HBX, with the intent of preventing gaps in health coverage")
  )
