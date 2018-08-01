# A model for grouping and organizing a {Person} with their related {FamilyMember FamilyMember(s)},
# benefit enrollment eligibility, financial assistance eligibility and availability, benefit enrollments,
# broker agents, and documents.
#
# Each family has one or more {FamilyMember FamilyMembers}, each associated with a {Person} instance.  Each
# Family has exactly one FamilyMember designated as the {#primary_applicant}. A Person can belong to
# more than one Family, but may be the primary_applicant of only one active Family.
#
# Family is a top level physical MongoDB Collection.

class Family
  require 'autoinc'

  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps
  # include Mongoid::Versioning
  include Sortable
  include Mongoid::Autoinc
  # include DocumentsVerificationStatus

  IMMEDIATE_FAMILY = %w(self spouse life_partner child ward foster_child adopted_child stepson_or_stepdaughter stepchild domestic_partner)

  field :version, type: Integer, default: 1
  embeds_many :versions, class_name: self.name, validate: false, cyclic: true, inverse_of: nil

  field :hbx_assigned_id, type: Integer
  increments :hbx_assigned_id, seed: 9999

  field :e_case_id, type: String # Eligibility system foreign key
  field :e_status_code, type: String
  field :application_type, type: String
  field :renewal_consent_through_year, type: Integer # Authorize auto-renewal elibility check through this year (CCYY format)

  field :is_active, type: Boolean, default: true # ApplicationGroup active on the Exchange?
  field :submitted_at, type: DateTime # Date application was created on authority system
  field :updated_by, type: String
  field :status, type: String, default: "" # for aptc block
  field :min_verification_due_date, type: Date, default: nil
  field :vlp_documents_status, type: String

  belongs_to  :person

  # Collection of insured:  employees, consumers, residents

  # All current and former members of this group
  embeds_many :family_members, cascade_callbacks: true
  embeds_many :special_enrollment_periods, cascade_callbacks: true
  # embeds_many :broker_agency_accounts #depricated
  embeds_many :broker_agency_accounts, class_name: "BenefitSponsors::Accounts::BrokerAgencyAccount"
  embeds_many :general_agency_accounts
  embeds_many :documents, as: :documentable

  # before_save :clear_blank_fields

  accepts_nested_attributes_for :special_enrollment_periods, :family_members, 
                                :broker_agency_accounts, :general_agency_accounts

  # index({hbx_assigned_id: 1}, {unique: true})
  index({e_case_id: 1}, { sparse: true })
  index({submitted_at: 1})
  index({person_id: 1})
  index({is_active: 1})

  # child model indexes
  index({"family_members._id" => 1})
  index({"family_members.person_id" => 1, hbx_assigned_id: 1})
  index({"family_members.broker_role_id" => 1})
  index({"family_members.is_primary_applicant" => 1})
  index({"family_members.hbx_enrollment_exemption.certificate_number" => 1})

  index({"special_enrollment_periods._id" => 1})

  index({"family_members.person_id" => 1, hbx_assigned_id: 1})

  index({"broker_agency_accounts.broker_agency_profile_id" => 1, "broker_agency_accounts.is_active" => 1}, {name: "broker_families_search_index"})
  # index("households.tax_households_id")

  validates :renewal_consent_through_year,
            numericality: {only_integer: true, inclusion: 2014..2025},
            :allow_nil => true

  # validate :family_integrity


  scope :all_with_single_family_member,     ->{ exists({:'family_members.1' => false}) }
  scope :all_with_multiple_family_members,  ->{ exists({:'family_members.1' => true})  }

  scope :by_writing_agent_id,               ->(broker_id){ where(broker_agency_accounts: {:$elemMatch=> {writing_agent_id: broker_id, is_active: true}})}
  scope :by_broker_agency_profile_id,       ->(broker_agency_profile_id) { where(broker_agency_accounts: {:$elemMatch=> {is_active: true, "$or": [{benefit_sponsors_broker_agency_profile_id: broker_agency_profile_id}, {broker_agency_profile_id: broker_agency_profile_id}]}})}
  scope :by_general_agency_profile_id,      ->(general_agency_profile_id) { where(general_agency_accounts: {:$elemMatch=> {general_agency_profile_id: general_agency_profile_id, aasm_state: "active"}})}


  def find_primary_applicant_by_person(person)
    find_all_by_person(person).select() { |f| f.primary_applicant.person.id.to_s == person.id.to_s }
  end
end
