puts "*"*80
puts "::: Cleaning LifeEvents :::"
Employer.delete_all

LifeEvent.create!(
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


LifeEvent.create!(
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

LifeEvent.create!(
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

LifeEvent.create!(
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

LifeEvent.create!(
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

LifeEvent.create!(
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

LifeEvent.create!(
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

LifeEvent.create!(
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

LifeEvent.create!(
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

LifeEvent.create!(
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

LifeEvent.create!(
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

LifeEvent.create!(
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

LifeEvent.create!(
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

LifeEvent.create!(
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


LifeEvent.create!(
  title: "Open enrollment",
  description: "Consumer is enrolling during an annual open enrollment period",
  kind: :add_member,
  market_kind: :individual,
  edi_reason: "Initial Enrollment",
  valid_examples: [],
  invalid_examples: [],
  effective_on_kind: :date_range,
  coverage_offset_kind: 15,
  pre_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: ["11-01-2015".."01-31-2016"],
  post_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 0,
  is_self_attested: true,
  event_kind: "",
  start_of_sep: "60 days before loss of MEC",
  coverage_effective_date: "If before loss of coverage: First day of the month after MEC will end. If after loss of MEC: First day of the month following plan selection (not following 15th of month rule)")

LifeEvent.create!(
  title: "Loss of other health coverage",
  description: "Consumer lost other minimum essential coverage involuntarily",
  kind: :add_member,
  market_kind: :individual,
  edi_reason: "",
  valid_examples: [
      "Loss of coverage from a job or family member’s job",
      "Aging off of a parent’s plan",
      "No longer qualifying for Medicaid",
      "Expiration of a pre-ACA individual market plan",
      "Expiration of COBRA benefits"
    ],
  invalid_examples: [
      "Loss of employer coverage due to failure to sign up or pay",
      "Loss of coverage under another DCHL plan due to failure to pay",
      "Dropping COBRA coverage",
      "Other voluntary termination of coverage"
    ],
    effective_on_kind: ,
  coverage_offset_kind: :first_of_month,
  pre_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  post_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60, # "60 days before loss of coverage and 60 days after",
  is_self_attested: true,
  event_kind: "",
  start_of_sep: "60 days before loss of MEC",
  coverage_effective_date: "If before loss of coverage: First day of the month after MEC will end. If after loss of MEC: First day of the month following plan selection (not following 15th of month rule)")

LifeEvent.create!(
  title: "Mid-Month Loss of MEC",
  description: "Consumer losing MEC on a date other than the last day of a month",
  kind: :add_member,
  market_kind: :individual,
  edi_reason: "",
  valid_examples: [
      "Consumer selects plan before end of the month before coverage ends."
    ],
  invalid_examples: [],
  pre_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  effective_on_kind: ,
  coverage_offset_kind: :first_of_month,
  post_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60, # "60 days before the day of the loss of coverage",
  event: "coverage end date"
  is_self_attested: true,
  event_kind: "",
  start_of_sep: "60 days before coverage ends",
  coverage_effective_date: "The effective date is the first day of the month in which the prior coverage is terminating (following plan selection).")

LifeEvent.create!(
  title: "Adding a person to household",
  title: "I had a baby",
  description: "Household adds a member due to marriage, birth, adoption, placement for adoption, or placement in foster care",
    effective_on_kind: ,
  valid_examples: [
      "Birth, adoption, placement for adoption, or placement in foster care of a child",
      "Marriage"
    ],
  invalid_examples: [
    "A consumer’s unmarried partner moves in with the consumer"
  ],
  coverage_offset_kind: :date_of_event,
  pre_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 0,
  post_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  coverage_effective_date: "Date of birth, adoption, placement for adoption, placement in foster care, or marriage.  For marriage: First day of the month following plan selection (not following 15th of month rule); this applies to all members of household")

LifeEvent.create!(
  title: "Adding a person to household",
  title: "I adopted a child",
  description: "Household adds a member due to marriage, birth, adoption, placement for adoption, or placement in foster care",
  kind: :add_member,
  market_kind: :individual,
  edi_reason: "",
    effective_on_kind: ,
  coverage_offset_kind: :date_of_event,
  valid_examples: [
      "Birth, adoption, placement for adoption, or placement in foster care of a child",
      "Marriage"
    ],
  invalid_examples: [
    "A consumer’s unmarried partner moves in with the consumer"
  ],
  pre_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 0,
  post_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  coverage_effective_date: "Date of birth, adoption, placement for adoption, placement in foster care, or marriage.  For marriage: First day of the month following plan selection (not following 15th of month rule); this applies to all members of household")

LifeEvent.create!(
  title: "Adding a person to household",
  title: "I married",
  description: "Household adds a member due to marriage, birth, adoption, placement for adoption, or placement in foster care",
  kind: :add_member,
  market_kind: :individual,
  edi_reason: "",
  valid_examples: [
      "Birth, adoption, placement for adoption, or placement in foster care of a child",
      "Marriage"
    ],
  invalid_examples: [
    "A consumer’s unmarried partner moves in with the consumer"
  ],
    effective_on_kind: ,
  coverage_offset_kind: :date_of_event,
  pre_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 0,
  post_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  coverage_effective_date: "Date of birth, adoption, placement for adoption, placement in foster care, or marriage.  For marriage: First day of the month following plan selection (not following 15th of month rule); this applies to all members of household")

LifeEvent.create!(
  title: "Moving into the District of Columbia",
  description: "Consumer or a member of the consumer’s tax household moves to the District",
  kind: :add_member,
  market_kind: :individual,
  edi_reason: "",
  valid_examples: [
    "Permanent move to DC"
  ],
  invalid_examples: [
    "Temporary move to DC",
    "Moving from one address in DC to another address in DC",
    "Traveling and then returning to DC if consumer was a DC resident while traveling"
  ],
  effective_on_kind: ,
  coverage_offset_kind: :date_of_event,
  pre_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 0,
  post_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: true,
  event_kind: "",
  start_of_sep: "Date of move    ",
  coverage_effective_date: "Regular effective date")


LifeEvent.create!(
  title: "Change in APTC/CSR",
  description: "Consumer has a change in circumstances that makes him or her newly eligible or ineligible for APTC changes eligibility for CSR. Only applies to those already enrolled in a QHP.",
  valid_examples: [
    "A QHP enrollee has a change that results in a change in the amount of CSRA QHP enrollee has a change that results in gaining or losing APTC",
    "A QHP enrollee has a change that does not change amount of APTC or CSR",
    "A QHP enrollee has a change that changes the amount of APTC but not CSR",
    "Someone who is not enrolled in a QHP has a change in circumstances that makes him or her eligible for a QHP"
  kind: :add_member,
  market_kind: :individual,
  edi_reason: "",
  ],
  invalid_examples: [],
  effective_on_kind: ,
  coverage_offset_kind: "",
  pre_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 0,
  post_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: true,
  event_kind: "",
  start_of_sep: "Date of eligibility redetermination (NOTE: this is not necessarily the date the customer reported the change)",
  coverage_effective_date: "Regular effective date")

LifeEvent.create!(
  title: "Change in immigration status",
  description: "Consumer gains status a citizen, national, or lawfully present immigrant",
  valid_examples: [
    "Becoming a US citizen",
    "Becoming a legal permanent resident",
    "Gaining Deferred Action for Childhood Arrivals status (DACA, which is not a lawfully present immigration status)",
    "Renewing a VISA (staying lawfully present)"
  kind: :add_member,
  market_kind: :individual,
  edi_reason: "",
  ],
  invalid_examples: [],
  effective_on_kind: ,
  coverage_offset_kind: "",
  pre_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 0,
  post_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: true,
  event_kind: "",
  start_of_sep: "Date change was verified (NOTE: this is not necessarily the date the customer reported the change)",
  coverage_effective_date: "Regular effective date")

LifeEvent.create!(
  title: "Being Native American",
  description: "American Indians/Alaskan Natives can enroll in a plan at any time",
  kind: :add_member,
  market_kind: :individual,
  edi_reason: "",
  valid_examples: [],
  invalid_examples: [],
  effective_on_kind: ,
  coverage_offset_kind: "",
  pre_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 0,
  post_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 30,
  is_self_attested: true,
  event_kind: "",
  start_of_sep: "Date approved by HBX",    
  coverage_effective_date: "Regular effective date")

LifeEvent.create!(
  title: "Erroneous enrollment, HBX/HHS",
  description: "Enrollment or non-enrollment in QHP unintentional, inadvertent, or erroneous and is result of error, misrepresentation, or inaction by an agent of HBX or HHS",
  valid_examples: [
    "Consumer was not able to enroll due to error messages",
    "CSR took an action that caused consumer to miss open enrollment"
  ],
  invalid_examples: [
  kind: :add_member,
  market_kind: :individual,
  edi_reason: "",
    "Consumer enrolled but did not pay premium after receiving an invoice"
  ],
  effective_on_kind: ,
  coverage_offset_kind: "",
  pre_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 0,
  post_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: true,
  event_kind: "",
  start_of_sep: "Date approved by HBX",    
  coverage_effective_date: "Regular effective date")

LifeEvent.create!(
  title: "Erroneous enrollment, QHP issuer",
  description: "Enrollment or non-enrollment in QHP unintentional, inadvertent, or erroneous and is result of error, misrepresentation, or inaction by an agent of a QHP issuer (as determined by DISB)",
  valid_examples: [
    "Carrier representative gave misinformation about plan, and the consumer acted on this information and enrolled in the plan"
    ],
  invalid_examples: [
    "Consumer enrolled but did not pay premium after receiving an invoice",
  kind: :add_member,
  market_kind: :individual,
  edi_reason: "",
    "Consumer picked the wrong plan"
  ],
  effective_on_kind: ,
  coverage_offset_kind: "",
  pre_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 0,
  post_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: true,
  event_kind: "",
  start_of_sep: "Date approved by HBX",    
  coverage_effective_date: "Regular effective date")

LifeEvent.create!(
  title: "Misconduct of non-Exchange entity providing enrollment assistance",
  description: "Consumer was not enrolled, was enrolled in the wrong plan, or was eligible for but did not receive APTC or CSR due to misconduct by a non-Exchange entity providing enrollment assistance",
  valid_examples: [
    "Assister enrolled consumer in a plan other than the plan the consumer told the assister he or she wanted to enroll in"
    ],
  invalid_examples: [
    "Consumer enrolled but did not pay premium after receiving an invoice",
  kind: :add_member,
  market_kind: :individual,
  edi_reason: "",
    "Consumer picked the wrong plan"
    ],
    effective_on_kind: ,
  coverage_offset_kind: "",
  pre_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 0,
  post_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: true,
  event_kind: "",
  start_of_sep: "Date approved by HBX",       
  coverage_effective_date: "Regular effective date")

LifeEvent.create!(
  title: "QHP violated its contract",
  description: "The QHP the person enrolled in substantially violated a material provision of its contract with the consumer",
  valid_examples: [
    "Consumer paid premium, but plan never provided coverage or card"
    ],
  invalid_examples: [
  kind: :add_member,
  market_kind: :individual,
  edi_reason: "",
    "Customer doesn’t like the coverage provided by the plan"
  ],
  effective_on_kind: ,
  coverage_offset_kind: "",
  pre_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 0,
  post_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: true,
  event_kind: "",
  start_of_sep: "Date approved by HBX",       
  coverage_effective_date: "Regular effective date")

LifeEvent.create!(
  title: "Found ineligible for Medicaid after open enrollment ended",
  description: "Consumer had pending Medicaid eligibility at the end of open enrollment, but was found ineligible after open enrollment.",
  valid_examples: [
    "Applicant had pending eligibility for Medicaid, but provided documents showing income over the Medicaid threshold and was determined ineligible"
    ],
  invalid_examples: [
    kind: :add_member,
    market_kind: :individual,
    edi_reason: "",
    "Applicant was determined ineligible for Medicaid due to failure to provide verification documents in a timely manner"
    ],
    effective_on_kind: ,
    coverage_offset_kind: "",
    pre_event_pre_event_sep_in_days: 0,
    post_event_sep_in_days: 0,
    post_event_pre_event_sep_in_days: 0,
    post_event_sep_in_days: 60,
    is_self_attested: true,
    event_kind: "",
    start_of_sep: "Date consumer received notice of Medicaid ineligibility",
    coverage_effective_date: "Regular effective date")

LifeEvent.create!(
  title: "Consumer’s employer applied to SHOP exchange but was found ineligible",
  description: "Consumer did not enroll in a QHP because consumer’s employer was applying to provide coverage through SHOP during open enrollment. Consumer’s employer was found ineligible to participate in SHOP after the end of open enrollment",
  valid_examples: [
    "Employer applied in March of 2014 for SHOP exchange. Employer did not meet minimum participation requirements for SHOP and was found ineligible in April of 2014"
    ],
  invalid_examples: [
  kind: :add_member,
  market_kind: :individual,
  edi_reason: "",
    "Employer applied to participate in SHOP exchange after individual open enrollment has ended and is found ineligible"
    ],
    effective_on_kind: ,
  coverage_offset_kind: "",
  pre_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 0,
  post_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: true,
  event_kind: "",
  start_of_sep: "Date consumer received notice of SHOP ineligibility    ",
  coverage_effective_date: "Regular effective date")

LifeEvent.create!(
  title: "Exceptional circumstance due to a natural disaster",
  description: "(HBX)   A natural disaster prevented consumer from enrolling during open enrollment or an SEP",
  valid_examples: [
    "Earthquake",
    "Massive flooding",
    "Hurricane"
  kind: :add_member,
  market_kind: :individual,
  edi_reason: "",
    ],
  invalid_examples: [],
  effective_on_kind: ,
  coverage_offset_kind: "",
  pre_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 0,
  post_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: true,
  event_kind: "",
  start_of_sep: "Day of disaster (or last day of multi-day disaster)",
  coverage_effective_date: "Regular effective date")

LifeEvent.create!(
  title: "Exceptional circumstance due to medical emergency",
  description: "A serious medical condition prevented consumer from enrolling during open enrollment or an SEP",
  valid_examples: [
    "Unexpected hospitalization",
    "Temporary cognitive disability"
  kind: :add_member,
  market_kind: :individual,
  edi_reason: "",
  ],
  invalid_examples: [],
  effective_on_kind: ,
  coverage_offset_kind: "",
  pre_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 0,
  post_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: true,
  event_kind: "",
  start_of_sep: "Date approved by HBX",       
  coverage_effective_date: "Regular effective date")

LifeEvent.create!(
  title: "Exceptional circumstance due to system outages around plan selection deadlines",
  description: "DC Health Link outage or outage of federal or local data sources around the plan selection deadline prevented consumer from enrolling during open enrollment or an SEP",
  kind: :add_member,
  market_kind: :individual,
  edi_reason: "",
  valid_examples: [],
  invalid_examples: [],
  effective_on_kind: ,
  coverage_offset_kind: "",
  pre_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 0,
  post_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: true,
  event_kind: "",
  start_of_sep: "Day of outage",
  coverage_effective_date: "Regular effective date")

LifeEvent.create!(
  title: "Exceptional circumstances due to being a victim of domestic abuse",
  description: "A person is leaving an abusive spouse or domestic partner",
  kind: :add_member,
  market_kind: :individual,
  edi_reason: "",
  valid_examples: [],
  invalid_examples: [],
  effective_on_kind: ,
  coverage_offset_kind: "",
  pre_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 0,
  post_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: true,
  event_kind: "",
  start_of_sep: "Date person leaves spouse or domestic partner",
  coverage_effective_date: "Regular effective date")

LifeEvent.create!(
  title: "Exceptional circumstances due to loss of eligibility for hardship exemption",
  description: "Consumer who received a certificate of exemption from the individual mandate for a month or months during the coverage year who loses eligibility for the exemption.",
  kind: :add_member,
  market_kind: :individual,
  edi_reason: "",
  valid_examples: [],
  invalid_examples: [],
  effective_on_kind: ,
  coverage_offset_kind: "",
  pre_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 30,
  post_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: true,
  event_kind: "",
  start_of_sep: "30 days prior to date of ineligibility for exemption",
  coverage_effective_date: "Regular effective date")

LifeEvent.create!(
  title: "Exceptional circumstance for those beginning or ending AmeriCorps State and National, VISTA, or NCCC service",
  description: "An individual is a member of AmeriCorps State and National, VISTA, or NCCC.",
  kind: :add_member,
  market_kind: :individual,
  edi_reason: "",
  valid_examples: [],
  invalid_examples: [],
  effective_on_kind: ,
  coverage_offset_kind: "",
  pre_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 0,
  post_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: true,
  event_kind: "",
  start_of_sep: "Date person begins or ends service in one of the three programs",
  coverage_effective_date: "Regular effective date")

LifeEvent.create!(
  title: "Divorce/Domestic Partnership Termination",
  description: "Consumer divorces or legally separates",
  kind: :add_member,
  market_kind: :individual,
  edi_reason: "",
  valid_examples: [],
  invalid_examples: [],
  effective_on_kind: ,
  coverage_offset_kind: :first_of_month,
  pre_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 0,
  post_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: true,
  event_kind: "",
  start_of_sep: "Date of divorce, legal separation, partnership termination",
  coverage_effective_date: "First day of the month following plan selection (not following 15th of month rule); this applies to all members of household")

LifeEvent.create!(
  title: "Entering a domestic partnership",
  description: "Entering a domestic partnership as permitted or recognized by the District of Columbia",
  kind: :add_member,
  market_kind: :individual,
  edi_reason: "",
  valid_examples: [],
  invalid_examples: [],
  effective_on_kind: ,
  coverage_offset_kind: :first_of_month,
  pre_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 0,
  post_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: true,
  event_kind: "",
  start_of_sep: "Date partnership entered into",
  coverage_effective_date: "First day of the month following plan selection (not following 15th of month rule); this applies to all members of household")

LifeEvent.create!(
  title: "Medical coverage order (mandate)",
  description: "A person is required by a court (through a medical insurance coverage order) for themselves or someone else",
  kind: :add_member,
  market_kind: :individual,
  edi_reason: "",
  valid_examples: [],
  invalid_examples: [],
  effective_on_kind: ,
  coverage_offset_kind: "",
  pre_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 0,
  post_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: "60 days ",
  is_self_attested: true,
  event_kind: "date of court order",
  start_of_sep: "Date of the court order",
  coverage_effective_date: "Regular effective date"))

LifeEvent.create!(
  title: "Dependent loss of ESI due to employee gaining Medicare",
  description: "A dependent is losing access to ESI coverage because the employee is enrolling in Medicare",
  kind: :add_member,
  market_kind: :individual,
  edi_reason: "",
  valid_examples: [],
  invalid_examples: [],
  effective_on_kind: ,
  coverage_offset_kind: :first_of_month,
  pre_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  post_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 60,
  is_self_attested: true,
  event_kind: "coverage end date",
  start_of_sep: "60 days before loss of MEC",
  coverage_effective_date: "If before loss of coverage: First day of the month after MEC will end. If after loss of MEC: First day of the month following plan selection (not following 15th of month rule)")

LifeEvent.create!(
  title: "Employer failure to pay COBRA premiums on time",
  description: "Consumer loses access to COBRA because the employer responsible for submitting premiums fails to submit them on time",
  kind: :add_member,
  market_kind: :individual,
  edi_reason: "",
  valid_examples: [],
  invalid_examples: [],
  effective_on_kind: ,
  coverage_offset_kind: "",
  pre_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 0,
  post_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 0,
  is_self_attested: true,
  event_kind: "",
  start_of_sep: "Based on circumstances as determined by HBX Date of loss of coverage",
  coverage_effective_date: "As determined by HBX, with the intent of preventing gaps in health coverage")

LifeEvent.create!(
  title: "Uninsured District Residents Facing IRS Tax Penalties",
  description: "Consumer who may be subject to a federal tax penalty because they did not have health insurance, who when preparing the 2014 federal taxes the taxpayer first became aware of the tax penalty after open enrollment ended on February 15, 2015, or filed their 2014 federal tax return, and the taxpayer paid a tax penalty to the IRS for not having health coverage in 2014.",
  kind: :add_member,
  market_kind: :individual,
  edi_reason: "",
  valid_examples: [],
  invalid_examples: [],
  effective_on_kind: ,
  coverage_offset_kind: :date_range,
  pre_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: 0,
  post_event_pre_event_sep_in_days: 0,
  post_event_sep_in_days: ["03-15-2015".."04-30-2015"],
  is_self_attested: true,
  event_kind: "",
  start_of_sep: "Date reported",   
  coverage_effective_date: "Regular effective date")

puts "::: LifeEvents Complete :::"
puts "*"*80
