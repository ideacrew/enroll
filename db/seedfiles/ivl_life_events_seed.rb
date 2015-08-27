QualifyingLifeEventKind.create!(
  title: "Dependent loss of ESI due to employee gaining Medicare",
  tool_tip: "A dependent is losing access to ESI coverage because the employee is enrolling in Medicare",
  action_kind: "add_benefit",
  event_kind_label: "Coverage end date",
  market_kind: "individual",
  ordinal_position: 100,
  reason: "employee_gaining_medicare",
  edi_code: "33-LOST ACCESS TO MEC", 
  effective_on_kinds: ["first_of_this_month", "first_of_next_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60, # "60 days before loss of coverage and 60 days after",
  is_self_attested: true,
    # event_kind_label: "coverage end date",
    # start_of_sep: "60 days before loss of MEC",
    # coverage_effective_date: "If before loss of coverage: First day of the month after MEC will end. If after loss of MEC: First day of the month following plan selection (not following 15th of month rule)")
  )

QualifyingLifeEventKind.create!(
  title: "Myself or a family member has lost other coverage",
  tool_tip: "Consumer lost other minimum essential coverage involuntarily",
  action_kind: "add_benefit",
  event_kind_label: "Coverage end date",
  market_kind: "individual",
  ordinal_position: 100,
  reason: "lost_access_to_mec",
  edi_code: "33-LOST ACCESS TO MEC", 
  effective_on_kinds: ["first_of_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60, # "60 days before loss of coverage and 60 days after",
  is_self_attested: true,
    # start_of_sep: "60 days before loss of MEC",
    # coverage_effective_date: "If before loss of coverage: First day of the month after MEC will end. If after loss of MEC: First day of the month following plan selection (not following 15th of month rule)")
  )

QualifyingLifeEventKind.create!(
  title: "I've had a baby",
  tool_tip: "Household adds a member due to marriage, birth, adoption, placement for adoption, or placement in foster care",
  action_kind: "add_member",
  market_kind: "individual",
  event_kind_label: "Date of birth",
  reason: " ",
  edi_code: "02-BIRTH", 
  ordinal_position: 100,
  effective_on_kinds: ["date_of_event", "first_of_next_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: true,
    # coverage_effective_date: "Date of birth, adoption, placement for adoption, placement in foster care, or marriage.  For marriage: First day of the month following plan selection (not following 15th of month rule); this applies to all members of household")
  )

QualifyingLifeEventKind.create!(
  title: "I've adopted a child",
  tool_tip: "Household adds a member due to marriage, birth, adoption, placement for adoption, or placement in foster care",
  action_kind: "add_member",
  market_kind: "individual",
  event_kind_label: "Date of adoption",
  ordinal_position: 100,
  reason: " ",
  edi_code: "05-ADOPTION", 
  effective_on_kinds: ["date_of_event", "first_of_next_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: true,
    # coverage_effective_date: "Date of birth, adoption, placement for adoption, placement in foster care, or marriage.  For marriage: First day of the month following plan selection (not following 15th of month rule); this applies to all members of household")
  )

QualifyingLifeEventKind.create!(
  title: "I've married",
  tool_tip: "Household adds a member due to marriage, birth, adoption, placement for adoption, or placement in foster care",
  action_kind: "add_member",
  market_kind: "individual",
  event_kind_label: "Date of marriage",
  ordinal_position: 100,
  reason: " ",
  edi_code: "32-MARRIAGE", 
  effective_on_kinds: ["first_of_next_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: true,
    # coverage_effective_date: "Date of birth, adoption, placement for adoption, placement in foster care, or marriage.  For marriage: First day of the month following plan selection (not following 15th of month rule); this applies to all members of household")
  )

QualifyingLifeEventKind.create!(
  title: "I've entered into a legal domestic partnership",
  tool_tip: "Entering a domestic partnership as permitted or recognized by the District of Columbia",
  action_kind: "add_member",
  market_kind: "individual",
  event_kind_label: "Date of legal domestic partnership",
  ordinal_position: 100,
  reason: " ",
  edi_code: "33-ENTERING DOMESTIC PARTNERSHIP", 
  effective_on_kinds: ["first_of_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: true,
    # start_of_sep: "Date partnership entered into",
    # coverage_effective_date: "First day of the month following plan selection (not following 15th of month rule); this applies to all members of household")
  )

QualifyingLifeEventKind.create!(
  title: "I've divorced or ended domestic partnership",
  tool_tip: "Consumer divorces, ends domestic partnership or legally separates",
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
  title: "I've moved into the District of Columbia",
  tool_tip: "Consumer or a member of the consumer’s tax household moves to the District",
  action_kind: "add_benefit",
  market_kind: "individual",
  event_kind_label: "Date of move",
  ordinal_position: 100,
  reason: "move_to_state",
  edi_code: "43-CHANGE OF LOCATION", 
  effective_on_kinds: ["first_of_next_month"],
  pre_event_sep_in_days: 0,
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
  is_self_attested: true,
    # start_of_sep: "Date of eligibility redetermination (NOTE: this is not necessarily the date the customer reported the change)",
    # coverage_effective_date: "Regular effective date")
  )

QualifyingLifeEventKind.create!(
  title: "My immigration status has changed",
  tool_tip: "Consumer gains status as citizen, national, or lawfully present immigrant",
  action_kind: "add_benefit",
  market_kind: "individual",
  event_kind_label: "Date of change",
  ordinal_position: 100,
  reason: " ",
  edi_code: " ",
  effective_on_kinds: ["first_of_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: true,
    # start_of_sep: "Date change was verified (NOTE: this is not necessarily the date the customer reported the change)",
    # coverage_effective_date: "Regular effective date")
  )

QualifyingLifeEventKind.create!(
  title: "I'm a Native American",
  tool_tip: "American Indians/Alaskan Natives can enroll in a plan at any time",
  action_kind: "add_member",
  market_kind: "individual",
  ordinal_position: 100,
  reason: " ",
  edi_code: " ",
  effective_on_kinds: ["first_of_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 30,
  is_self_attested: true,
    # start_of_sep: "Date approved by HBX",    
    # coverage_effective_date: "Regular effective date")
  )

QualifyingLifeEventKind.create!(
  title: "Erroneous enrollment, HBX/HHS",
  tool_tip: "Enrollment or non-enrollment in QHP unintentional, inadvertent, or erroneous and is result of error, misrepresentation, or inaction by an agent of HBX or HHS",
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
  title: "Erroneous enrollment, QHP issuer",
  tool_tip: "Enrollment or non-enrollment in QHP unintentional, inadvertent, or erroneous and is result of error, misrepresentation, or inaction by an agent of a QHP issuer (as determined by DISB)",
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
  title: "Misconduct of non-Exchange entity providing enrollment assistance",
  tool_tip: "Consumer was not enrolled, was enrolled in the wrong plan, or was eligible for but did not receive APTC or CSR due to misconduct by a non-Exchange entity providing enrollment assistance",
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
  title: "QHP violated its contract",
  tool_tip: "The QHP the person enrolled in substantially violated a material provision of its contract with the consumer",
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
  title: "Found ineligible for Medicaid after open enrollment ended",
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
  title: "Consumer’s employer applied to SHOP exchange but was found ineligible",
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
  title: "Exceptional circumstance due to a natural disaster",
  tool_tip: "(HBX)   A natural disaster prevented consumer from enrolling during open enrollment or an SEP",
  action_kind: "add_member",
  market_kind: "individual",
  ordinal_position: 100,
  reason: " ",
  edi_code: " ",
  effective_on_kinds: ["first_of_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: true,
    # start_of_sep: "Day of disaster (or last day of multi-day disaster)",
    # coverage_effective_date: "Regular effective date")
  )

QualifyingLifeEventKind.create!(
  title: "Exceptional circumstance due to medical emergency",
  tool_tip: "A serious medical condition prevented consumer from enrolling during open enrollment or an SEP",
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
  title: "Exceptional circumstance due to system outages around plan selection deadlines",
  tool_tip: "DC Health Link outage or outage of federal or local data sources around the plan selection deadline prevented consumer from enrolling during open enrollment or an SEP",
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
  title: "Exceptional circumstances due to being a victim of domestic abuse",
  tool_tip: "A person is leaving an abusive spouse or domestic partner",
  action_kind: "add_member",
  market_kind: "individual",
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
  title: "Exceptional circumstances due to loss of eligibility for hardship exemption",
  tool_tip: "Consumer who received a certificate of exemption from the individual mandate for a month or months during the coverage year who loses eligibility for the exemption.",
  action_kind: "add_member",
  market_kind: "individual",
  ordinal_position: 100,
  reason: " ",
  edi_code: " ",
  effective_on_kinds: ["first_of_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: false,
    # start_of_sep: "30 days prior to date of ineligibility for exemption",
    # coverage_effective_date: "Regular effective date")
  )

QualifyingLifeEventKind.create!(
  title: "Exceptional circumstance for those beginning or ending AmeriCorps State and National, VISTA, or NCCC service",
  tool_tip: "An individual is a member of AmeriCorps State and National, VISTA, or NCCC.",
  action_kind: "add_member",
  market_kind: "individual",
  ordinal_position: 100,
  reason: " ",
  edi_code: " ",
  effective_on_kinds: ["first_of_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: false,
    # start_of_sep: "Date person begins or ends service in one of the three programs",
    # coverage_effective_date: "Regular effective date")
  )

QualifyingLifeEventKind.create!(
  title: "Medical coverage order (mandate)",
  tool_tip: "A person is required by a court (through a medical insurance coverage order) for themselves or someone else",
  action_kind: "add_member",
  market_kind: "individual",
  event_kind_label: "Court-ordered coverage start date",
  ordinal_position: 100,
  reason: " ",
  edi_code: " ",
  effective_on_kinds: ["first_of_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: false,
    # start_of_sep: "Date of the court order",
    # coverage_effective_date: "Regular effective date")
  )

QualifyingLifeEventKind.create!(
  title: "My Employer failed to pay premiums on time",
  tool_tip: "Consumer loses access to COBRA because the employer responsible for submitting premiums fails to submit them on time",
  action_kind: "add_member",
  market_kind: "individual",
  ordinal_position: 100,
  reason: " ",
  edi_code: " ",
  effective_on_kinds: ["first_of_month"],
  pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: false,
    # start_of_sep: "Based on circumstances as determined by HBX Date of loss of coverage",
    # coverage_effective_date: "As determined by HBX, with the intent of preventing gaps in health coverage")
  )
