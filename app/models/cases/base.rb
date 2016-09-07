class Cases::Base
  include Mongoid::Document

  embeds_many :caseworker_notes, as: :commentable
  embeds_many :customer_notes, as: :commentable
  embeds_many :documents, as: :documentable

  # Approval workflow
  # Service ticket reference

  PRIORITY_KINDS  = %w(low normal high urgent)
  STATUS_KINDS    = %w(new assigned in_progress closed)

  field :category, type: String   # Eligibility, Enrollment?  or Tracker?
  field :assignee, type: String
  field :priority, type: String
  field :status, type: String
  field :started_at, type: Time
  field :closed_at, type: Time

  # def self.included(base)
  #   base.send(:field, :reason, :type => String)
  # end

  # journal

  PERSON                  = %W(identity citizen_status lawful_presence_status location role contact)

  # application detail - is person applying for coverage
  # financial release - IRS up to 5 years
  # physical vs tax HH
  # documentation details for citizenship status
  # external evidences -- federal hub responses
  # notices and documents
  # enrollments

  identity  = [
                  { consumer_role: { 
                        attributes: %w(first_name middle_name last_name name_pfx name_sfx ssn dob gender),
                        scopes: %w(consumer_role),
                        where: :any
                      } 
                    },
                  { employee_role: %w(first_name middle_name last_name name_pfx name_sfx ssn dob gender) },
                  { resident_role: %w(first_name middle_name last_name name_pfx name_sfx ssn dob gender) },
                ]

  citizen_status  = [
                      { resident_role: %w(first_name middle_name last_name name_pfx name_sfx ssn dob gender) },
                      ]              

  demographic     = [
                        { consumer_role: %w(first_name middle_name last_name name_pfx name_sfx ssn dob gender) },
                      ]

  location        = [
                        { addresses: {
                              %w(addresses), 
                              scopes: [
                                        { consumer_role.addresses.kind.in => ["home", "mailing"] },
                                        { employee_role.addresses.kind.in => ["home", "mailing"] },
                                        { resident_role.addresses.kind.in => ["home", "mailing"] },
                                        { resident_role.addresses.kind.in => ["home", "mailing"] },
                                        ]
                              where: [
                                consumer_role, kind: :home, ]
                            }
                          },
                        { consumer_role: %w(addresses) },
                        { employee_role: %w(addresses) },
                        { resident_role: %w(addresses) },
                      ]



  lawful_presence_status  = {models: [
                                {model: :person,
                                  # tracker_class_name: :"journals/person_transaction",
                                  attributes: %w()
                                }
                              ]}

  location                = {models: [
                                {model: :address, 
                                  # tracker_class_name: :"journals/person_transaction",
                                  kinds: [:home], 
                                  attributes: %w(address_1 address_2 address_3 city state zip)}
                              ]}

  contact                 = {models: [
                                {model: :person, 
                                  # tracker_class_name: :"journals/person_transaction",
                                  attributes: %w(addresses emails phones)} 
                              ]}

  role                    = {models: [
                                {model: :person, 
                                  # tracker_class_name: :"journals/person_transaction",
                                  attributes: %w(consumer_role employee_roles employer_staff_roles 
                                    broker_agency_staff_roles general_agency_Staff_roles csr_role hbx_staff_role assister_role)} 
                              ]}

  document                = {models: [
                                {model: :person, 
                                  # tracker_class_name: :"journals/person_transaction",
                                  attributes: %w(documents)}
                              ]}



  FAMILY      = %w(special_enrollment_period household enrollment_period eligibility_determination ) # enrollment_period_kinds: sep, new_hire, cobra
  special_enrollment_period =  {models: [
                                  {model: :family,
                                    # tracker_class_name: :"journals/family_transaction",
                                    attributes: %w(special_enrollment_periods)}
                                  ]}

  household                 =  {models: [
                                  {model: :family,
                                    # tracker_class_name: :"journals/family_transaction",
                                    attributes: %w(households)}
                                  ]}


  ENROLLMENT_ELIGBILITY = %w(unassisted_individual assisted_individual employer_sponsored )
  BENEFIT_ENROLLMENT    = %w(initial maintenance auto_renewed renewed reinstated waived )


  CASE_WORKER = %w()
  HBX         = %w(open_enrollment_period settngs)
  ACCOUNT     = %w()
  EMPLOYER    = %w()
  BROKER      = %w()

  change_model
  change_id

  # Eligibility/Assistance
  ## QLEs
  ## Disabled child (prevent age-off)
  ## Financial assistance change
  ## Incarceration status
  ## Residency status

  # New Enrollment
  ## QLEs

  # Eligibility/Assistance (affects all existing/new enrollments)
  ## Change APTC
  ## Transfer subscriber/re-enrollment
  ### Medicare eligibility (QLE)
  ### Death
  ## Lawful presence verification expired
  ## Verified non-lawful presence
  ## Verified non-citizen

  # Existing enrollment
  ## Change effective date
  ## Add members to coverage
  ### loss of Medicaid eligibility (Loss of MEC QLE?)
  ## Drop members from coverage
  ### age-off
  ### newly Medicaid eligibile
  ### incarceration
  ## Dispute carrier cancel

  # Carrier signals
  ## Cancel enrollment
  ## Reinstate benefit
  ## Effectuation enrollment
  ## Address change
  ## Phone change
  ## Email change
  ## Member death

  ELIGIBILITY   = []
  ENROLLMENT    = []
  FAMILY        = []
  PERSON        = []
  EMPLOYEE_ROLE = []
  CONSUMER_ROLE = []

  HBX_EVIDENCE_KINDS    = %w(
                              open_enrollment_period_added
                              open_enrollment_period_dropped
                              open_enrollment_period_updated
                            )

  FAMILY_EVIDENCE_KINDS = %w(
                              created
                              archived
                              family_member_added
                              family_member_dropped

                              benefit_effective_date_disputed
                              financial_assistance_eligibility_disputed
                              aptc_disputed
                              carrier_cancel_disputed

                              benefit_enrollment_submitted
                              benefit_enrollment_acknowledged
                              benefit_enrollment_effectuated
                              benefit_enrollment_canceled
                              benefit_enrollment_terminated
                              benefit_effective_date_updated
                              income_updated
                              financial_assistance_eligibility_determined
                              financial_assistance_eligibility_updated
                              tax_filing_status_changed
                              aptc_updated

                              broker_added
                              broker_dropped

                              qualifying_life_event
                              incarceration_status_updated
                              disability_status_updated
                              residency_status_determined
                              residency_status_updated
                            )

  PERSON_EVIDENCE_KINDS = %w(
                              created
                              archived
                              merged

                              name_updated
                              dob_updated
                              ssn_updated
                              gender_updated
                              family_relationship_updated
                              address_updated
                              email_updated
                              phone_updated

                              identity_determined
                              hbx_role_added
                              hbx_role_dropped
                              language_preference_updated
                              ethnic_profile_udpated

                              citizen_status_determined
                              citizen_status_updated
                              lawful_presence_status_determined
                              lawful_presence_status_updated
                              lawful_presence_status_disputed
                            )

  EMPLOYEE_EVIDENCE_KINDS = %w(
                                benefit_enrollment_eligible
                                employment_terminated
                                benefit_waived
                                qualifying_life_event
                                cobra_enrollment_submitted
                                cobra_enrollment_canceled
                                cobra_enrollment_terminated
                              )

  ALL_EVIDENCE_KINDS      = %w(
                                eligibility
                                enrollment
                                person_information
                              )


  # embeds_one  :verification, class_name: "Workflows::Verification", as: :verifiable
  embeds_many :case_notes, as: :commentable
  embeds_many :consumer_notes, as: :commentable


  field :title, type: String
  field :role_kind, type: String  # model name
  field :evidence_kind, type: String
  field :effective_on, type: Date
  field :reason, type: String

  field :assigned_to,  type: BSON::ObjectId   # TODO: support multiple assignments
  field :approved_by, type: BSON::ObjectId

  field :related_case_ids, type: Array, default: []
  field :related_crm_ids,  type: Array, default: []

  field :history_attributes, type: Array, default: [] # used for tracking changes.
  # accepts_nested_attributes_for :"workflows/verification", :case_notes, :consumer_notes

  def get_data
  end

end