# frozen_string_literal: true

# A model for grouping and organizing a {Person} with their related {FamilyMember FamilyMember(s)},
# benefit enrollment eligibility, financial assistance eligibility and availability, benefit enrollments,
# broker agents, and documents.
#
# Each family has one or more {FamilyMember FamilyMembers}, each associated with a {Person} instance.  Each
# Family has exactly one FamilyMember designated as the {#primary_applicant}. A Person can belong to
# more than one Family, but may be the primary_applicant of only one active Family.
#
# Family is a top level physical MongoDB Collection.

# rubocop:disable all

class Family
  require 'autoinc'

  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps
  # include Mongoid::Versioning
  include Sortable
  include Mongoid::Autoinc
  # include DocumentsVerificationStatus

  IMMEDIATE_FAMILY = %w[self spouse life_partner child ward foster_child adopted_child stepson_or_stepdaughter stepchild domestic_partner].freeze

  field :version, type: Integer, default: 1
  embeds_many :versions, class_name: self.name, validate: false, cyclic: true, inverse_of: nil

  field :hbx_assigned_id, type: Integer
  increments :hbx_assigned_id, seed: 9999

  field :e_case_id, type: String # Eligibility system foreign key
  #field :fin_app_id, type: String # Financial Application ID, Use Family ID instead
  field :haven_app_id, type: String
  field :e_status_code, type: String
  field :application_type, type: String
  field :renewal_consent_through_year, type: Integer # Authorize auto-renewal elibility check through this year (CCYY format)

  field :is_active, type: Boolean, default: true # ApplicationGroup active on the Exchange?
  field :submitted_at, type: DateTime # Date application was created on authority system
  field :updated_by, type: String
  field :status, type: String, default: "" # for aptc block
  field :min_verification_due_date, type: Date, default: nil
  field :vlp_documents_status, type: String

  field :is_applying_for_assistance, type: Boolean

  belongs_to  :person

  # Collection of insured:  employees, consumers, residents

  # All current and former members of this group
  embeds_many :family_members, cascade_callbacks: true
  embeds_many :special_enrollment_periods, cascade_callbacks: true
  embeds_many :irs_groups, cascade_callbacks: true
  embeds_many :households, cascade_callbacks: true, :before_add => :reset_active_household
  embeds_many :broker_agency_accounts
  embeds_many :general_agency_accounts
  embeds_many :documents, as: :documentable
  has_many :applications, class_name: "FinancialAssistance::Application"
  has_many :payment_transactions

  after_initialize :build_household
  before_save :clear_blank_fields

  accepts_nested_attributes_for :special_enrollment_periods, :family_members, :irs_groups,
                                :households, :broker_agency_accounts, :general_agency_accounts, :applications

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

  index({"households.hbx_enrollments.broker_agency_profile_id" => 1}, {sparse: true})
  index({"households.hbx_enrollments.effective_on" => 1})
  index({"households.hbx_enrollments.benefit_group_assignment_id" => 1})
  index({"households.hbx_enrollments.benefit_group_id" => 1})

  index({"households.hbx_enrollments.aasm_state" => 1,
         "households.hbx_enrollments.created_at" => 1},
        {name: "state_and_created"})

  index({"households.hbx_enrollments.kind" => 1,
         "households.hbx_enrollments.aasm_state" => 1,
         "households.hbx_enrollments.effective_on" => 1,
         "households.hbx_enrollments.terminated_on" => 1},
        {name: "kind_and_state_and_created_and_terminated"})

  index({"households.hbx_enrollments.is_any_enrollment_member_outstanding" => 1})
  index({"households.hbx_enrollments.is_any_enrollment_member_outstanding" => 1,
         "households.hbx_enrollments.aasm_state" => 1,
         "households.hbx_enrollments.terminated_on" => 1},
        {name: "is_any_enrollment_member_outstanding_and_aasm_state_and_terminated_on"})

  index({"households.hbx_enrollments.kind" => 1,
         "households.hbx_enrollments.aasm_state" => 1,
         "households.hbx_enrollments.is_any_enrollment_member_outstanding" => 1,
         "households.hbx_enrollments.effective_on" => 1},
        {name: "kind_and_aasm_state_and_is_any_enrollment_member_outstanding_and_effective_on"})

  index({"households.hbx_enrollments._id" => 1})
  index({"households.hbx_enrollments.kind" => 1,
         "households.hbx_enrollments.aasm_state" => 1,
         "households.hbx_enrollments.coverage_kind" => 1,
         "households.hbx_enrollments.effective_on" => 1},
        {name: "kind_and_state_and_coverage_kind_effective_date"})

  index({"households.hbx_enrollments.plan_id" => 1}, { sparse: true })
  index({"households.hbx_enrollments.writing_agent_id" => 1}, { sparse: true })
  index({"households.hbx_enrollments.hbx_id" => 1})
  index({"households.hbx_enrollments.kind" => 1})
  index({"households.hbx_enrollments.submitted_at" => 1})
  index({"households.hbx_enrollments.effective_on" => 1})
  index({"households.hbx_enrollments.terminated_on" => 1}, { sparse: true })
  index({"households.hbx_enrollments.applied_aptc_amount" => 1})

  index({"households.tax_households.hbx_assigned_id" => 1})
  index({"households.tax_households.effective_starting_on" => 1})
  index({"households.tax_households.effective_ending_on" => 1})
  index({"households.tax_households.tax_household_member.financial_statement.submitted_date" => 1})

  index({"households.tax_households.eligibility_determinations._id" => 1})
  index({"households.tax_households.eligibility_determinations.e_pdc_id" => 1})
  index({"households.tax_households.eligibility_determinations.determined_on" => 1})
  index({"households.tax_households.eligibility_determinations.determined_at" => 1})
  index({"households.tax_households.eligibility_determinations.max_aptc.cents" => 1})

  index({"irs_groups.hbx_assigned_id" => 1})

  index({"special_enrollment_periods._id" => 1})

  index({"family_members.person_id" => 1, hbx_assigned_id: 1})

  index({"broker_agency_accounts.broker_agency_profile_id" => 1, "broker_agency_accounts.is_active" => 1}, {name: "broker_families_search_index"})
  # index("households.tax_households_id")

  validates :renewal_consent_through_year,
            numericality: {only_integer: true, inclusion: 2014..2025},
            :allow_nil => true

  validate :family_integrity

  after_initialize :build_household

  # after_save :update_family_search_collection
  # after_destroy :remove_family_search_record

  scope :with_enrollment_hbx_id, lambda { |enrollment_hbx_id|
    where("households.hbx_enrollments.hbx_id" => enrollment_hbx_id)
  }

  scope :all_with_single_family_member,     ->{ exists({:'family_members.1' => false}) }
  scope :all_with_multiple_family_members,  ->{ exists({:'family_members.1' => true})  }


  scope :all_current_households,            ->{ exists(households: true).order_by(:start_on.desc).limit(1).only(:_id, :"households._id") }
  scope :all_tax_households,                ->{ exists(:"households.tax_households" => true) }

  scope :by_writing_agent_id,               ->(broker_id){ where(broker_agency_accounts: {:$elemMatch => {writing_agent_id: broker_id, is_active: true}})}
  scope :by_broker_agency_profile_id,       ->(broker_agency_profile_id) { where(broker_agency_accounts: {:$elemMatch => {broker_agency_profile_id: broker_agency_profile_id, is_active: true}})}
  scope :by_general_agency_profile_id,      ->(general_agency_profile_id) { where(general_agency_accounts: {:$elemMatch => {general_agency_profile_id: general_agency_profile_id, aasm_state: "active"}})}

  scope :all_assistance_applying,           lambda {
                                              unscoped.exists(:"households.tax_households.eligibility_determinations" => true).order(
                                                :"households.tax_households.eligibility_determinations.determined_at".desc
                                              )
                                            }

  scope :all_aptc_hbx_enrollments,      ->{ unscoped.where(:"households.hbx_enrollments.applied_aptc_amount.cents".gt => 0)}
  scope :all_unassisted,                ->{ exists(:"households.tax_households.eligibility_determinations" => false) }

  scope :all_eligible_for_assistance,   ->{ exists(:"households.tax_households.eligibility_determinations" => true) }

  scope :all_assistance_receiving,      lambda {
                                          unscoped.where(:"households.tax_households.eligibility_determinations.max_aptc.cents".gt => 0).order(
                                            :"households.tax_households.eligibility_determinations.determined_at".desc
                                          )
                                        }

  scope :all_active_assistance_receiving_for_current_year, lambda {
    unscoped.where(:"households.tax_households.eligibility_determinations.max_aptc.cents".gt => 0).order(
      :"households.tax_households.eligibility_determinations.determined_at".desc
    ).and(
      :"households.tax_households.effective_ending_on" => nil
    ).and(
      :"households.tax_households.effective_starting_on".gte => Date.new(TimeKeeper.date_of_record.year)
    ).and(
      :"households.tax_households.effective_starting_on".lte => Date.new(TimeKeeper.date_of_record.year).end_of_year
    )
  }

  scope :active_assistance_receiving,   ->{ all_assistance_receiving.where(:"households.tax_households.effective_ending_on" => nil) }
  scope :all_plan_shopping,             ->{ exists(:"households.hbx_enrollments" => true) }


  scope :by_eligibility_determination_date_range, lambda { |start_at, end_at|
    where(
      :"households.tax_households.eligibility_determinations.determined_on".gte => start_at
    ).and(
      :"households.tax_households.eligibility_determinations.determined_on".lte => end_at
    )
  }

  scope :all_with_hbx_enrollments,              -> { exists(:"households.hbx_enrollments" => true) }
  scope :by_datetime_range,                     ->(start_at, end_at){ where(:created_at.gte => start_at).and(:created_at.lte => end_at) }
  scope :all_enrollments,                       ->{  where(:"households.hbx_enrollments.aasm_state".in => HbxEnrollment::ENROLLED_STATUSES) }
  scope :all_enrolled_and_enrolling_enrollments,->{  where(:"households.hbx_enrollments.aasm_state".in => (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::RENEWAL_STATUSES))}
  scope :all_enrollments_by_writing_agent_id,   ->(broker_id){ where(:"households.hbx_enrollments.writing_agent_id" => broker_id) }
  scope :all_enrollments_by_benefit_group_id,   ->(benefit_group_id){where(:"households.hbx_enrollments.benefit_group_id" => benefit_group_id) }
  scope :by_enrollment_individual_market,       ->{ where(:"households.hbx_enrollments.kind".in => ["individual", "unassisted_qhp", "insurance_assisted_qhp", "streamlined_medicaid", "emergency_medicaid", "hcr_chip"]) }
  scope :by_enrollment_shop_market,             ->{ where(:"households.hbx_enrollments.kind".in => ["employer_sponsored", "employer_sponsored_cobra"]) }
  scope :by_enrollment_renewing,                ->{ where(:"households.hbx_enrollments.aasm_state".in => HbxEnrollment::RENEWAL_STATUSES) }
  scope :by_enrollment_created_datetime_range,  ->(start_at, end_at){ where(:"households.hbx_enrollments.created_at" => { "$gte" => start_at, "$lte" => end_at})}
  scope :by_enrollment_updated_datetime_range,  ->(start_at, end_at){ where(:"households.hbx_enrollments.updated_at" => { "$gte" => start_at, "$lte" => end_at})}
  scope :by_enrollment_effective_date_range,    ->(start_on, end_on){ where(:"households.hbx_enrollments.effective_on" => { "$gte" => start_on, "$lte" => end_on})}
  scope :non_enrolled,                          ->{ where(:"households.hbx_enrollments.aasm_state".nin => HbxEnrollment::ENROLLED_STATUSES) }
  scope :sep_eligible,                          ->{ where(:"active_seps.count".gt => 0) }
  scope :coverage_waived,                       ->{ where(:"households.hbx_enrollments.aasm_state".in => HbxEnrollment::WAIVED_STATUSES) }
  scope :having_unverified_enrollment,          ->{ by_enrollment_individual_market.all_enrollments.where(:"households.hbx_enrollments.is_any_enrollment_member_outstanding" => true)}
  scope :vlp_fully_uploaded,                    ->{ where(vlp_documents_status: "Fully Uploaded")}
  scope :vlp_partially_uploaded,                ->{ where(vlp_documents_status: "Partially Uploaded")}
  scope :vlp_none_uploaded,                     ->{ where(:vlp_documents_status.in => ["None",nil])}
  scope :outstanding_verification,              ->{ by_enrollment_individual_market.all_enrollments.where(:"households.hbx_enrollments" => {"$elemMatch" => {:is_any_enrollment_member_outstanding => true, :effective_on => { :"$gte" => TimeKeeper.date_of_record.beginning_of_year, :"$lte" => TimeKeeper.date_of_record.end_of_year }}}) }
  scope :outstanding_verification_datatable,    ->{ by_enrollment_individual_market.all_enrolled_and_enrolling_enrollments.where(:"households.hbx_enrollments" => {"$elemMatch" => {:is_any_enrollment_member_outstanding => true}})}

  def self.approved_applications
    where :_id.in => FinancialAssistance::Application.where('aasm_state' => 'determined').map(&:family_id)
  end

  def self.submitted_applications
    where :_id.in => FinancialAssistance::Application.where('aasm_state' => 'submitted').map(&:family_id)
  end

  def self.approved_applications_for_year(year)
    where :_id.in => FinancialAssistance::Application.where('aasm_state' => 'determined', 'assistance_year' => year).map(&:family_id)
  end

  def active_broker_agency_account
    broker_agency_accounts.detect { |baa| baa.is_active? }
  end

  def coverage_waived?
    latest_household.hbx_enrollments.any? && latest_household.hbx_enrollments.waived.any?
  end

  def remove_family_search_record
    Searches::FamilySearch.where("id" => self.id).delete_all
  end

  def latest_household
    return households.first if households.size == 1
    households.order_by(:submitted_at.desc).limit(1).only(:households).first
  end

  def active_household
    # households.detect { |household| household.is_active? }
    latest_household
  end

  def enrolled_benefits
    # latest_household.try(:enrolled_hbx_enrollments)
  end

  def terminated_benefits; end

  def renewal_benefits; end

  def currently_enrolled_plans(enrollment)
    enrolled_enrollments = active_household.hbx_enrollments.enrolled_and_renewing.by_coverage_kind(enrollment.coverage_kind)

    if enrollment.is_shop?
      bg_ids = enrollment.benefit_group.plan_year.benefit_groups.map(&:id)
      enrolled_enrollments = enrolled_enrollments.where(:benefit_group_id.in => bg_ids)
    end

    enrolled_enrollments.map(&:plan)
  end

  def currently_enrolled_plans_ids(enrollment)
    currently_enrolled_plans(enrollment).collect(&:id)
  end

  def enrollments
    return [] if  latest_household.blank?
    latest_household.hbx_enrollments.show_enrollments
  end

  # The {FamilyMember} who is head and 'owner' of this family instance.
  #
  # @example Who is the primary applicant for this family?
  #   model.primary_applicant
  #
  # @return [ FamilyMember ] the designated head of this family
  def primary_applicant
    family_members.detect { |family_member| family_member.is_primary_applicant? && family_member.is_active? }
  end

  def primary_person
    primary_applicant&.person
  end

  def primary_family_member=(new_primary_family_member)
    self.primary_family_member.is_primary_applicant = false unless primary_family_member.blank?

    existing_family_member = find_family_member_by_person(new_primary_family_member)
    if existing_family_member.present?
      existing_family_member.is_primary_applicant = true
    else
      add_family_member(new_primary_family_member, is_primary_applicant: true)
    end

    primary_family_member
  end

  def terminated_enrollments
    return [] if  latest_household.blank?
    enrollments.can_update_enrollments_end_date.order_by(:created_at => "DESC").select{|hbx| ["coverage_terminated", "coverage_termination_pending"].include?(hbx.aasm_state)}
  end

  # @deprecated Use {primary_applicant}
  alias primary_family_member primary_applicant

  def consent_applicant
    family_members.detect { |family_member| family_member.is_consent_applicant? && family_member.is_active? }
  end

  # Get all active {FamilyMember FamilyMembers}
  #
  # @example Who are the active members for this family?
  #   model.active_family_members
  #
  # @return [ Array<FamilyMember> ] the active members of this family
  def active_family_members
    family_members.find_all { |family_member| family_member.is_active? }
  end

  # Get the {FamilyMember} associated with this {Person}
  #
  # @example Which {FamilyMember} references this {Person}?
  #   model.find_family_member_by_person
  #
  # @param person [ Person ] the {Person} to match
  #
  # @return [ FamilyMember ] the family member who matches this person
  def find_family_member_by_person(person)
    family_members.detect { |family_member| family_member.person_id.to_s == person._id.to_s }
  end

  def is_eligible_to_enroll?(options = {})
    !current_enrollment_eligibility_reasons(qle: options[:qle]).empty?
  end

  def current_enrollment_eligibility_reasons(options = {})
    current_special_enrollment_periods.collect do |sep|
      EnrollmentEligibilityReason.new(sep)
    end + current_eligible_open_enrollments(qle: options[:qle])
  end

  # Determine if this family has enrollment eligibility under SHOP or Individual market open enrollment
  #
  # @example Is this family under SHOP or Individual market open enrollment?
  #   model.is_under_open_enrollment?
  #
  # @see is_under_shop_open_enrollment?
  # @see is_under_ivl_open_enrollment?
  #
  # @return [ true, false ] true if under SHOP or Individual market open enrollment, false if not under SHOP or Individual market open enrollment
  def is_under_open_enrollment?
    !current_eligible_open_enrollments.empty?
  end

  # Determine if this family has enrollment eligibility under Individual market open enrollment
  #
  # @example Is this family under Individual market open enrollment?
  #   model.is_under_ivl_open_enrollment?
  #
  # @see is_under_shop_open_enrollment?
  # @see is_under_open_enrollment?
  #
  # @return [ true, false ] true if under Individual market open enrollment, false if not under Individual market open enrollment
  def is_under_ivl_open_enrollment?
    !current_ivl_eligible_open_enrollments.empty?
  end

  # Determine if this family has enrollment eligibility under SHOP market open enrollment
  #
  # @example Is this family under SHOP market open enrollment?
  #   model.is_under_shop_open_enrollment?
  #
  # @see is_under_ivl_open_enrollment?
  # @see is_under_open_enrollment?
  #
  # @return [ true, false ] true if under SHOP market open enrollment, false if not under SHOP market open enrollment
  def is_under_shop_open_enrollment?
    !current_shop_eligible_open_enrollments.empty?
  end

  # Get list of Individual and SHOP market {EnrollmentEligibilityReason EnrollmentEligibilityReasons} currently available to this family
  #
  # @example Get the list of {EnrollmentEligibilityReason EnrollmentEligibilityReasons}
  #   model.current_ivl_eligible_open_enrollments
  #
  # @see current_ivl_eligible_open_enrollments
  # @see current_shop_eligible_open_enrollments
  #
  # @return [ Array<EnrollmentEligibilityReason> ] The SHOP and Individual Market {EnrollmentEligibilityReasons} active for this family on today's date
  def current_eligible_open_enrollments(options = {})
    current_shop_eligible_open_enrollments(qle: options[:qle]) + current_ivl_eligible_open_enrollments
  end

  # Get list of Individual market {EnrollmentEligibilityReason EnrollmentEligibilityReasons} currently available to this family
  #
  # @example Get the list of {EnrollmentEligibilityReason EnrollmentEligibilityReasons}
  #   model.current_ivl_eligible_open_enrollments
  #
  # @return [ Array<EnrollmentEligibilityReason> ] The Individual market {EnrollmentEligibilityReasons} active for this family on today's date
  def current_ivl_eligible_open_enrollments
    eligible_open_enrollments = []

    benefit_sponsorship = HbxProfile.current_hbx.try(:benefit_sponsorship)
    (benefit_sponsorship.try(:benefit_coverage_periods) || []).each do |benefit_coverage_period|
      eligible_open_enrollments << EnrollmentEligibilityReason.new(benefit_sponsorship) if benefit_coverage_period.open_enrollment_contains?(TimeKeeper.date_of_record)
    end

    eligible_open_enrollments
  end

  # Get list of SHOP market {EnrollmentEligibilityReason EnrollmentEligibilityReasons} currently available to this family
  #
  # @example Get the list of {EnrollmentEligibilityReason EnrollmentEligibilityReasons}
  #   model.current_shop_eligible_open_enrollments
  #
  # @return [ Array<EnrollmentEligibilityReason> ] The SHOP market {EnrollmentEligibilityReasons} active for this family on today's date
  def current_shop_eligible_open_enrollments(options = {})
    eligible_open_enrollments = []

    active_employee_roles = primary_applicant.person.active_employee_roles if primary_applicant.present?
    active_employee_roles.each do |employee_role|
      next unless (benefit_group = employee_role.benefit_group(qle: options[:qle])) &&
                  (employer_profile = employee_role.try(:employer_profile))
      employer_profile.try(:published_plan_year).try(:enrolling?) &&
        benefit_group.effective_on_for(employee_role.hired_on) > benefit_group.start_on

      eligible_open_enrollments << EnrollmentEligibilityReason.new(employer_profile)
    end

    eligible_open_enrollments

    # original implementation - to be removed after testing is proved to work - 2015-09-03
    # return [] unless primary_applicant
    # pri_person = primary_applicant.person
    # return [] unless pri_person
    # employee_role = pri_person.employee_roles.first
    # return [] unless employee_role
    # employer_profile = employee_role.employer_profile
    # return [] unless employer_profile
    # benefit_group = employee_role.benefit_group
    # return [] unless benefit_group
    # return [] if benefit_group.effective_on_for(employee_role.hired_on) > benefit_group.start_on
    # return [] unless employer_profile.published_plan_year.enrolling?
    # [EnrollmentEligibilityReason.new(employer_profile)]
  end

  # Determine if this family has an active {SpecialEnrollmentPeriod} (SEP) enrollment eligibility
  #
  # @example Is this family under a {SpecialEnrollmentPeriod}
  #   model.is_under_special_enrollment_period?
  #
  # @return [ true, false ] true if under a SEP, false if not under a SEP
  def is_under_special_enrollment_period?
    return false if special_enrollment_periods.empty?
    !current_special_enrollment_periods.empty?
  end

  # Get list of {SpecialEnrollmentPeriod} (SEP) eligibilities currently available to this family
  #
  # @example Get the list of {SpecialEnrollmentPeriod SpecialEnrollmentPeriods}
  #   model.active_seps
  #
  # @deprecated Use current_special_enrollment_periods
  #
  # @return [ Array<SpecialEnrollmentPeriod> ] The SEP eligibilities active on today's date
  def active_seps
    special_enrollment_periods.find_all { |sep| sep.is_active? }
  end

  def latest_active_sep
    special_enrollment_periods.order_by(:submitted_at.desc).detect{ |sep| sep.is_active? }
  end

  # Get list of HBX Admin assigned {SpecialEnrollmentPeriod} (SEP) eligibilities currently available to this family
  #
  # @example Get the list of HBX Admin assigned {SpecialEnrollmentPeriod SpecialEnrollmentPeriods}
  #   model.active_seps
  #
  # @return [ Array<SpecialEnrollmentPeriod> ] The HBX Admin assigned SEP eligibilities active on today's date
  def active_admin_seps
    special_enrollment_periods.find_all { |sep| sep.is_active? && sep.admin_flag }
  end

  # Get list of {SpecialEnrollmentPeriod} (SEP) eligibilities currently available to this family ordered
  # descending from start on date
  #
  # @example Get the list of {SpecialEnrollmentPeriod SpecialEnrollmentPeriods}
  #   model.current_special_enrollment_periods
  #
  # @see active_seps
  #
  # @return [ Array<SpecialEnrollmentPeriod> ] The SEP eligibilities active on today's date
  def current_special_enrollment_periods
    return [] if special_enrollment_periods.empty?
    seps = special_enrollment_periods.order_by(:start_on.desc).only(:special_enrollment_periods)
    seps.reduce([]) { |list, event| list << event if event.is_active?; list }
  end

  # Get the {SpecialEnrollmentPeriod} (SEP) eligibility currently available to this family with the
  # earliest coverage effective date, regardless of Individual or SHOP Market. This is a method to obtain
  # the 'most advantageous' coverage, based on earliest start date
  #
  # @see earliest_effective_shop_sep
  # @see earliest_effective_ivl_sep
  #
  # @example Get the {SpecialEnrollmentPeriod} with earliest effective date
  #   model.earliest_effective_sep
  #
  # @return [ SpecialEnrollmentPeriod ] The SEP eligibility active on today's date with earliest
  #   coverage effective date
  def earliest_effective_sep
    special_enrollment_periods.order_by(:effective_on.asc).to_a.detect{ |sep| sep.is_active? }
  end

  # Get the SHOP market {SpecialEnrollmentPeriod} (SEP) eligibility currently available to this
  # family with the earliest coverage effective date. This is a method to obtain the 'most advantageous' coverage,
  # based on earliest start date
  #
  # @example Get the SHOP market {SpecialEnrollmentPeriod} with earliest effective date
  #   model.earliest_effective_shop_sep
  #
  # @see earliest_effective_sep
  # @see earliest_effective_ivl_sep
  #
  # @return [ SpecialEnrollmentPeriod ] The SHOP market SEP eligibility active on today's date with earliest
  #   coverage effective date
  def earliest_effective_shop_sep
    special_enrollment_periods.shop_market.order_by(:effective_on.asc).to_a.detect{ |sep| sep.is_active? }
  end

  # Get the Individual market {SpecialEnrollmentPeriod} (SEP) eligibility currently available to this
  # family with the earliest coverage effective date. This is a method to obtain the 'most advantageous' coverage,
  # based on earliest start date
  #
  # @example Get the Individual market {SpecialEnrollmentPeriod} with earliest effective date
  #   model.earliest_effective_ivl_sep
  #
  # @see earliest_effective_sep
  # @see earliest_effective_shop_sep
  #
  # @return [ SpecialEnrollmentPeriod ] The Individual market SEP eligibility active on today's date with earliest
  #   coverage effective date
  def earliest_effective_ivl_sep
    special_enrollment_periods.individual_market.order_by(:effective_on.asc).to_a.detect{ |sep| sep.is_active? }
  end

  # Get the most recently created, active SHOP market {SpecialEnrollmentPeriod} (SEP) eligibility currently available to this family
  #
  # @example Get the most recent, active SHOP market {SpecialEnrollmentPeriod}
  #   model.latest_shop_sep
  #
  # @return [ SpecialEnrollmentPeriod ] The most recent, active SHOP market SEP eligibility
  def latest_shop_sep
    special_enrollment_periods.shop_market.order_by(:submitted_at.desc).to_a.detect{ |sep| sep.is_active? }
  end

  def terminate_date_for_shop_by_enrollment(enrollment = nil)
    if latest_shop_sep.present?
      coverage_end_date = if latest_shop_sep.qualifying_life_event_kind.reason == 'death'
                            latest_shop_sep.qle_on
                          else
                            latest_shop_sep.qle_on.end_of_month
                          end

      if enrollment.present?
        coverage_end_date = enrollment.effective_on if enrollment.effective_on >= coverage_end_date
      end
      coverage_end_date
    else
      TimeKeeper.date_of_record.end_of_month
    end
  end

  # Get the {SpecialEnrollmentPeriod} (SEP) eligibility currently available to this family with latest end on date
  #
  # @example Get the {SpecialEnrollmentPeriod} with latest end on date
  #   model.current_sep
  #
  # @return [ SpecialEnrollmentPeriod ] The SEP eligibility active on today's date with latest end on date
  def current_sep
    active_seps.max { |sep| sep.end_on }
  end

  def build_from_employee_role(employee_role)
    build_from_person(employee_role.person)
  end

  def build_from_person(person)
    add_family_member(person, is_primary_applicant: true)
    person.person_relationships.each { |kin| add_family_member(kin.relative) }
    self
  end

  def relate_new_member(person, relationship)
    primary_applicant_person.ensure_relationship_with(person, relationship, self.id) #old_code
    add_family_member(person)
  end

  # Create a {FamilyMember} referencing this {Person}
  #
  # @param [ Person ] person The person to add to the family.
  # @param [ Hash ] opts The options to create the family member.
  # @option opts [ true, false ] :is_primary_applicant (false) This person is the primary family member
  # @option opts [ true, false ] :is_coverage_applicant (true) This person may enroll in coverage
  # @option opts [ true, false ] :is_consent_applicant (false) This person is consent applicant
  #
  def add_family_member(person, **opts)
    is_primary_applicant  = opts[:is_primary_applicant]  || false
    is_coverage_applicant = opts[:is_coverage_applicant] || true
    is_consent_applicant  = opts[:is_consent_applicant]  || false

    existing_family_member = family_members.detect { |fm| fm.person_id.to_s == person.id.to_s }
    if existing_family_member
      active_household.add_household_coverage_member(existing_family_member)
      existing_family_member.is_active = true
      return existing_family_member
    end

    family_member = family_members.build(
      person: person,
      is_primary_applicant: is_primary_applicant,
      is_coverage_applicant: is_coverage_applicant,
      is_consent_applicant: is_consent_applicant
    )

    active_household.add_household_coverage_member(family_member)
    family_member
  end

  # Remove {FamilyMember} referenced by this {Person}
  #
  # @param [ Person ] person The {Person} to remove from the family.
  def remove_family_member(person)
    family_member = find_family_member_by_person(person)
    if family_member.present?
      family_member.is_active = false
      person.remove_relationship(self.id) #delete family reltionships associated to deleted member
      active_household.remove_family_member(family_member)
    end

    family_member
  end

  # Determine if {Person} is a member of this family
  #
  # @example Is this person a family member?
  #   model.person_is_family_member?(person)
  #
  # @return [ true, false ] true if the person is in the family, false if the person isn't in the family
  def person_is_family_member?(person)
    find_family_member_by_person(person).present?
  end

  # Get list of family members who are not the primary applicant
  #
  # @example Which family members are non-primary applicants?
  #   model.dependents
  #
  # @return [ Array<FamilyMember> ] the list of dependents are active and inactive
  def dependents
    family_members.reject(&:is_primary_applicant)
  end

  # Get list of family members who are not the primary applicant
  #
  # @example Which family members are non-primary applicants?
  #   model.dependents
  #
  # @return [ Array<FamilyMember> ] the list of dependents are active
  def active_dependents
    family_members.reject(&:is_primary_applicant).find_all { |family_member| family_member.is_active? }
  end

  def people_relationship_map
    map = {}
    people.each do |person|
      map[person] = person_relationships.detect { |r| r.object_person == person.id }.relationship_kind
    end
    map
  end

  def is_active?
    self.is_active
  end

  def find_matching_inactive_member(personish)
    inactive_members = family_members.reject(&:is_active)
    return nil if inactive_members.blank?
    if !personish.ssn.blank?
      inactive_members.detect { |mem| mem.person.ssn == personish.ssn }
    else
      return nil if personish.dob.blank?
      search_dob = personish.dob.strftime("%m/%d/%Y")
      inactive_members.detect do |mem|
        mp = mem.person
        mem_dob = mem.dob.blank? ? nil : mem.dob.strftime("%m/%d/%Y")
        (personish.last_name.downcase.strip == mp.last_name.downcase.strip) &&
          (personish.first_name.downcase.strip == mp.first_name.downcase.strip) &&
          (search_dob == mem_dob)
      end
    end
  end

  def hire_broker_agency(broker_role_id)
    return unless broker_role_id
    existing_agency = current_broker_agency
    broker_agency_profile_id = BrokerRole.find(broker_role_id).try(:broker_agency_profile_id)
    terminate_broker_agency if existing_agency
    start_on = Time.now
    broker_agency_account = BrokerAgencyAccount.new(broker_agency_profile_id: broker_agency_profile_id, writing_agent_id: broker_role_id, start_on: start_on, is_active: true)
    broker_agency_accounts.push(broker_agency_account)
    self.save
  end

  # Terminate the active Broker agency for this family
  #
  # @param terminate_on [ Date ] Date to end broker engagement
  def terminate_broker_agency(terminate_on = TimeKeeper.date_of_record)
    current_broker_agency.update_attributes!(end_on: (terminate_on.to_date - 1.day).end_of_day, is_active: false) if current_broker_agency.present?
  end

  # Get the active {BrokerAgencyAccount} account for this family. New Individual market enrollments will include this
  # broker in the enrollment transaction.  If this family has employer-sponsored benefits, transactions for those enrollments
  # will include the employer's broker choice rater than the family-designated broker.
  #
  # @example Get the active {BrokerAgencyAccount}
  #   model.current_broker_agency
  #
  # @see active_broker_roles
  # @see hire_broker_agency
  # @see terminate_broker_agency
  #
  # @return [ BrokerAgencyAccount ] The active broker agency account for this family
  def current_broker_agency
    broker_agency_accounts.detect { |account| account.is_active? }
  end

  # Get the {BrokerRole BrokerRoles} on active enrollments. This method queries enrollment transactions, thus may return
  # a broker who the family has since terminated.  Compare this to the active broker returned by {#current_broker_agency}.
  # If this family has employer-sponsored benefits, the employer's broker choice will appear in transactions for those enrollments.
  #
  # @example Get the active {BrokerRole BrokerRoles}
  #   model.active_broker_roles
  #
  # @see current_broker_agency
  #
  # @return [ Array<BrokerRole> ] The {BrokerRole BrokerRoles} on this family's active enrollments
  def active_broker_roles
    active_household.hbx_enrollments.reduce([]) { |b, e| b << e.broker_role if e.is_active? && !e.broker_role.blank? } || []
  end

  def any_unverified_enrollments?
    enrollments.verification_needed.any?
  end

  def latest_applicable_submitted_application
    return nil unless applications.present?
    applications.where(:assistance_year => HbxProfile.application_applicable_year, :aasm_state.in => ["submitted", "determined"]).order_by(:submitted_at => 'desc').first
  end

  def has_financial_assistance_verification?
    return false if applications.blank?
    latest_applicable_submitted_application.present? ? true : false
  end

  def application_in_progress
    # Do we disable creating new Applications if there is one already in “draft”?
    # Also implement the logic to populate assistance_year (current_year or next_year based on application done before/after OE)
    #applications.where(aasm_state: "draft", assistance_year: TimeKeeper.date_of_record.year).last
    applications.where(aasm_state: "draft").last
  end

  def active_approved_application
    # Returns the most recent application that is approved (has eligibility determination) for the current year.
    applications.where(aasm_state: "determined", assistance_year: HbxProfile.application_applicable_year).order_by(:submitted_at => 'desc').first
  end

  def approved_applications_for_year(year)
    # Returns the last application that is approved (has eligibility determination) for a given year.
    applications.where(aasm_state: "determined", assistance_year: year)
  end

  def approved_applications
    # Returns all approved applications
    applications.where(aasm_state: "determined")
  end

  def latest_submitted_application
    #Returns last application submitted, aasm state is not in draft
    applications.order_by(:submitted_at => 'desc').first
  end

  def latest_drafted_application
    #Returns last application submitted, aasm state is not in draft
    applications.order_by(:created_at => 'desc').first
  end

  class << self
    # Set the sort order to return families by primary applicant last_name, first_name
    def default_search_order
      [["primary_applicant.name_last", 1], ["primary_applicant.name_first", 1]]
    end

    def expire_individual_market_enrollments
      current_benefit_period = HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period
      query = {
        :effective_on.lt => current_benefit_period.start_on,
        :kind => 'individual',
        :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES - ['coverage_termination_pending', 'enrolled_contingent', 'unverified']
      }
      families = Family.where("households.hbx_enrollments" => {:$elemMatch => query})
      @logger = Logger.new("#{Rails.root}/log/expire_individual_market_enrollments_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log") if families.present?
      @logger&.info "Started expire_individual_market_enrollments process at #{TimeKeeper.datetime_of_record}"
      families.no_timeout.each do |family|

        @logger.info "--------------- Processing family_id: #{family.id} ---------------"
        family.active_household.hbx_enrollments.where(query).each do |enrollment|
          if enrollment.may_expire_coverage?
            enrollment.expire_coverage!
            @logger.info "Processed enrollment: #{enrollment.hbx_id}"
          end
        end
      rescue Exception => e
        Rails.logger.error "Unable to expire enrollments for family #{family.id}, error: #{e.backtrace}"
        @logger.info "Unable to expire enrollments for family #{family.id}, error: #{e.backtrace}"

      end
      @logger&.info "Ended begin_coverage_for_ivl_enrollments process at #{TimeKeeper.datetime_of_record}"
    end

    def begin_coverage_for_ivl_enrollments
      current_benefit_period = HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period
      query = {
        :effective_on => current_benefit_period.start_on,
        :kind => 'individual',
        :aasm_state => 'auto_renewing'
      }
      families = Family.where("households.hbx_enrollments" => {:$elemMatch => query})
      @logger = Logger.new("#{Rails.root}/log/begin_coverage_for_ivl_enrollments_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log") if families.present?
      @logger&.info "Started begin_coverage_for_ivl_enrollments process at #{TimeKeeper.datetime_of_record}"
      families.no_timeout.each do |family|

        @logger.info "--------------- Processing family_id: #{family.id} ---------------"
        family.active_household.hbx_enrollments.where(query).each do |enrollment|
          if enrollment.may_begin_coverage?
            enrollment.begin_coverage!
            @logger.info "Processed enrollment: #{enrollment.hbx_id}"
          end
        end
      rescue Exception => e
        Rails.logger.error "Unable to begin coverage(enrollments) for family #{family.id}, error: #{e.backtrace}"
        @logger.info "Unable to begin coverage(enrollments) for family #{family.id}, error: #{e.backtrace}"

      end
      @logger&.info "Ended begin_coverage_for_ivl_enrollments process at #{TimeKeeper.datetime_of_record}"
    end

    # Manage: SEPs, FamilyMemberAgeOff
    def advance_day(new_date)
      expire_individual_market_enrollments
      begin_coverage_for_ivl_enrollments
      send_enrollment_notice_for_ivl(new_date)
    end

    def send_enrollment_notice_for_ivl(new_date)
      start_time = (new_date - 2.days).in_time_zone("Eastern Time (US & Canada)").beginning_of_day
      end_time = (new_date - 2.days).in_time_zone("Eastern Time (US & Canada)").end_of_day
      families = Family.where({
                                "households.hbx_enrollments" => {
                                  "$elemMatch" => {
                                    "kind" => "individual",
                                    "aasm_state" => { "$in" => HbxEnrollment::ENROLLED_STATUSES },
                                    "created_at" => { "$gte" => start_time, "$lte" => end_time}
                                  }
                                }
                              })
      families.each do |family|

        person = family.primary_applicant.person
        IvlNoticesNotifierJob.perform_later(person.id.to_s, "enrollment_notice") if person.consumer_role.present?
      rescue Exception => e
        Rails.logger.error { "Unable to deliver enrollment notice #{person.hbx_id} due to #{e.inspect}" }

      end
    end

    def find_by_employee_role(employee_role)
      find_all_by_primary_applicant(employee_role.person).first
    end

    def find_or_build_from_employee_role(new_employee_role)
      existing_family = Family.find_by_employee_role(new_employee_role)

      if existing_family.present?
        existing_family
      else
        family = Family.new
        family.build_from_employee_role(new_employee_role)

        family.save!
        family
      end
    end

    # Get all families where this person is a member
    # @param person [ Person ] Person to match
    # @return [ Array<Family> ] The families where this person is a member
    def find_all_by_person(person)
      where("family_members.person_id" => person.id)
    end

    # Get the family where this person is the primary applicant
    # @param person [ Person ] Person to match
    # @return [ Array<Family> ] The families where this person is primary applicant
    def find_primary_applicant_by_person(person)
      find_all_by_person(person).select { |f| f.primary_applicant.person.id.to_s == person.id.to_s }
    end

    # @deprecated Use find_primary_applicant_by_person
    alias find_all_by_primary_applicant find_primary_applicant_by_person

    # @deprecated Use find_primary_applicant_by_person
    alias find_by_primary_family_member find_primary_applicant_by_person

    # @deprecated Use find_primary_applicant_by_person
    alias find_by_primary_applicant find_primary_applicant_by_person

    # Get the family(s) with this eligibility case identifier
    # @param id [ String ] Eligibility case ID to match
    # @return [ Array<Family> ] The families with this eligibilitye case id
    def find_by_case_id(id)
      where({"e_case_id" => id}).to_a
    end
  end

  def build_consumer_role(family_member, opts = {})
    person = family_member.person
    return if person.consumer_role.present?
    person.build_consumer_role({:is_applicant => false}.merge(opts))
    person.save!
  end

  def check_for_consumer_role
    if primary_applicant.person.is_consumer_role_active?
      active_family_members.each do |family_member|
        build_consumer_role(family_member) if family_member.person.is_consumer_role_active?
      end
    end
  end

  def build_resident_role(family_member, opts = {})
    person = family_member.person
    return if person.resident_role.present?
    person.build_resident_role({:is_applicant => false}.merge(opts))
    person.save!
  end

  def check_for_resident_role
    if primary_applicant.person.is_resident_role_active?
      active_family_members.each do |family_member|
        build_resident_role(family_member) if family_member.person.is_resident_role_active?
      end
    end
  end

  def save_relevant_coverage_households
    households.each do |household|
      household.coverage_households.each{|hh| hh.save }
    end
  end

  def has_aptc_hbx_enrollment?
    enrollments = begin
                    latest_household.hbx_enrollments.active
                  rescue StandardError
                    []
                  end
    enrollments.any? {|enrollment| enrollment.applied_aptc_amount > 0}
  end

  def self.by_special_enrollment_period_id(special_enrollment_period_id)
    Family.where("special_enrollment_periods._id" => special_enrollment_period_id)
  end

  # Get all {HbxEnrollment HbxEnrollments} under this family's active household.  Includes active and inactive enrollments.
  # @return [ Array<HbxEnrollment> ] The {HbxEnrollment HbxEnrollments} for this family's active household
  def all_enrollments
    active_household.hbx_enrollments if self.active_household.present?
  end

  def enrolled_hbx_enrollments
    latest_household.try(:enrolled_hbx_enrollments)
  end

  def enrolled_including_waived_hbx_enrollments
    latest_household.try(:enrolled_including_waived_hbx_enrollments)
  end

  # Get {HbxEnrollment HbxEnrollments} that meet application criteria for display in the UI
  # @see waivers_for_display
  # @return [ Array<HbxEnrollment> ] The {HbxEnrollment HbxEnrollments} filtered by display criteria
  def enrollments_for_display
    Family.collection.aggregate([
                                    {"$match" => {'_id' => self._id}},
                                    {"$unwind" => '$households'},
                                    {"$unwind" => '$households.hbx_enrollments'},
                                    {"$match" => {"households.hbx_enrollments.aasm_state" => {"$nin" => ['void', "coverage_canceled"]} }},
                                    {"$match" => {"households.hbx_enrollments.external_enrollment" => {"$ne" => true}}},
                                    {"$sort" => {"households.hbx_enrollments.submitted_at" => -1 }},
                                    {"$group" => {'_id' => {
                                      'year' => { "$year" => '$households.hbx_enrollments.effective_on'},
                                      'month' => { "$month" => '$households.hbx_enrollments.effective_on'},
                                      'day' => { "$dayOfMonth" => '$households.hbx_enrollments.effective_on'},
                                      'subscriber_id' => '$households.hbx_enrollments.enrollment_signature',
                                      'provider_id' => '$households.hbx_enrollments.carrier_profile_id',
                                      'benefit_group_id' => '$households.hbx_enrollments.benefit_group_id',
                                      'state' => '$households.hbx_enrollments.aasm_state',
                                      'market' => '$households.hbx_enrollments.kind',
                                      'coverage_kind' => '$households.hbx_enrollments.coverage_kind'
                                    },
                                                  "hbx_enrollment" => { "$first" => '$households.hbx_enrollments'}}},
                                    {"$project" => {'hbx_enrollment._id' => 1, '_id' => 1}}
                                ],
                                :allow_disk_use => true)
  end

  # Get waived {HbxEnrollment HbxEnrollments} that meet application criteria for display in the UI
  # @see enrollments_for_display
  # @return [ Array<HbxEnrollment> ] The {HbxEnrollment HbxEnrollments} filtered by display criteria
  def waivers_for_display
    Family.collection.aggregate([
                                    {"$match" => {'_id' => self._id}},
                                    {"$unwind" => '$households'},
                                    {"$unwind" => '$households.hbx_enrollments'},
                                    {"$match" => {'households.hbx_enrollments.aasm_state' => 'inactive'}},
                                    {"$sort" => {"households.hbx_enrollments.submitted_at" => -1 }},
                                    {"$group" => {'_id' => {'year' => { "$year" => '$households.hbx_enrollments.effective_on'},
                                                            'state' => '$households.hbx_enrollments.aasm_state',
                                                            'kind' => '$households.hbx_enrollments.kind',
                                                            'coverage_kind' => '$households.hbx_enrollments.coverage_kind'}, "hbx_enrollment" => { "$first" => '$households.hbx_enrollments'}}},
                                    {"$project" => {'hbx_enrollment._id' => 1, '_id' => 0}}
                                ],
                                :allow_disk_use => true)
  end

  def generate_family_search
    ::MapReduce::FamilySearchForFamily.populate_for(self)
  end

  #Used for RelationshipMatrix
  def build_relationship_matrix
    family_id = self.id
    family_members_id = family_members.where(is_active: true).map(&:person_id)
    matrix_size = family_members.where(is_active: true).count
    matrix = Array.new(matrix_size){Array.new(matrix_size)}
    id_map = {}
    family_members_id.each_with_index { |hmid, index| id_map.merge!(index => hmid) }
    matrix.each_with_index do |x, xi|
      x.each_with_index do |_y, yi|
        matrix[xi][yi] = find_existing_relationship(id_map[xi], id_map[yi], family_id)
        matrix[yi][xi] = find_existing_relationship(id_map[yi], id_map[xi], family_id)
      end
    end
    matrix = apply_rules_and_update_relationships(matrix, family_id)
    matrix
  end

  def find_existing_relationship(member_a_id, member_b_id, family_id)
    return "self" if member_a_id == member_b_id
    person = Person.find(member_a_id)
    rel = person.person_relationships.where(family_id: family_id, predecessor_id: member_a_id, successor_id: member_b_id).first
    return rel.kind if rel.present?
  end

  def find_all_relationships(matrix)
    id_map = {}
    family_members_id = family_members.where(is_active: true).map(&:person_id)
    family_members_id.each_with_index { |hmid, index| id_map.merge!(index => hmid) }
    all_relationships = []
    matrix.each_with_index do |x, xi|
      x.each_with_index do |_y, yi|
        next unless xi < yi
        relation = Person.find(id_map[xi]).person_relationships.where(family_id: self.id, predecessor_id: id_map[xi], successor_id: id_map[yi]).first
        relation_kind = relation.present? ? relation.kind : nil
        all_relationships << {:predecessor => id_map[xi], :relation => relation_kind,  :successor => id_map[yi]}
      end
    end
    all_relationships
  end

  def find_missing_relationships(matrix)
    id_map = {}
    family_members_id = family_members.where(is_active: true).map(&:person_id)
    family_members_id.each_with_index { |hmid, index| id_map.merge!(index => hmid) }
    missing_relationships = []
    matrix.each_with_index do |x, xi|
      x.each_with_index do |_y, yi|
        missing_relationships << {id_map[xi] => id_map[yi]} if (xi > yi) && matrix[xi][yi].blank?
      end
    end
    missing_relationships
  end

  def apply_rules_and_update_relationships(matrix, family_id)
    missing_relationship = find_missing_relationships(matrix)

    # Sibling rule
    missing_relationship.each do |rel|
      first_rel = rel.to_a.flatten.first
      second_rel = rel.to_a.flatten.second
      relation1 = Person.find(first_rel).person_relationships.where(family_id: family_id, predecessor_id: first_rel, kind: "child").to_a
      relation2 = Person.find(second_rel).person_relationships.where(family_id: family_id, predecessor_id: second_rel, kind: "child").to_a

      relation = relation1 + relation2
      s_ids = relation.collect(&:successor_id)

      next unless s_ids.count > s_ids.uniq.count
      members = Person.where(:id.in => rel.to_a.flatten)
      members.second.person_relationships.create(family_id: family_id, predecessor_id: members.second.id, successor_id: members.first.id, kind: "sibling")
      members.first.person_relationships.create(family_id: family_id, predecessor_id: members.first.id, successor_id: members.second.id, kind: "sibling")
      missing_relationship -= [rel] #Remove Updated Relation from list of missing relationships
    end

    #GrandParent/GrandChild
    missing_relationship.each do |rel|
      first_rel = rel.to_a.flatten.first
      second_rel = rel.to_a.flatten.second

      relation1 = Person.find(first_rel).person_relationships.where(family_id: family_id, predecessor_id: first_rel, :kind.in => ['parent', 'child']).to_a
      relation2 = Person.find(second_rel).person_relationships.where(family_id: family_id, predecessor_id: second_rel, :kind.in => ['parent', 'child']).to_a

      relation = relation1 + relation2
      s_ids = relation.collect(&:successor_id)

      s_ids.each do |p_id|
        parent_rel1 = Person.find(first_rel).person_relationships.where(family_id: family_id, successor_id: p_id, predecessor_id: first_rel, kind: "parent").first
        child_rel1 = Person.find(first_rel).person_relationships.where(family_id: family_id, successor_id: p_id, predecessor_id: first_rel, kind: "child").first
        parent_rel2 = Person.find(second_rel).person_relationships.where(family_id: family_id, successor_id: p_id, predecessor_id: second_rel, kind: "parent").first
        child_rel2 = Person.find(second_rel).person_relationships.where(family_id: family_id, successor_id: p_id, predecessor_id: second_rel, kind: "child").first

        if parent_rel1.present? && child_rel2.present?
          grandchild = Person.where(id: second_rel).first
          grandparent = Person.where(id: first_rel).first
          grandparent.person_relationships.create(family_id: family_id, predecessor_id: grandparent.id, successor_id: grandchild.id, kind: "grandparent")
          grandchild.person_relationships.create(family_id: family_id, predecessor_id: grandchild.id, successor_id: grandparent.id, kind: "grandchild")
          missing_relationship -= [rel] #Remove Updated Relation from list of missing relationships
          break
        elsif child_rel1.present? && parent_rel2.present?
          grandchild = Person.where(id: first_rel).first
          grandparent = Person.where(id: second_rel).first
          grandparent.person_relationships.create(family_id: family_id, predecessor_id: grandparent.id, successor_id: grandchild.id, kind: "grandparent")
          grandchild.person_relationships.create(family_id: family_id, predecessor_id: grandchild.id, successor_id: grandparent.id, kind: "grandchild")
          missing_relationship -= [rel] #Remove Updated Relation from list of missing relationships
          break
        end
      end
    end

    # Spouse Rule
    missing_relationship.each do |rel|
      first_rel = rel.to_a.flatten.first
      second_rel = rel.to_a.flatten.second

      parent_rel1 = Person.find(first_rel).person_relationships.where(family_id: family_id, predecessor_id: first_rel, kind: 'child').first
      parent_rel2 = Person.find(second_rel).person_relationships.where(family_id: family_id, predecessor_id: second_rel, kind: 'child').first

      next unless parent_rel1.present? && parent_rel2.present?
      spouse_relation = Person.find(parent_rel1.successor_id).person_relationships.where(family_id: family_id, predecessor_id: parent_rel1.successor_id, successor_id: parent_rel2.successor_id, kind: "spouse").first
      next unless spouse_relation.present?
      members = Person.where(:id.in => rel.to_a.flatten)
      members.second.person_relationships.create(family_id: family_id, predecessor_id: members.second.id, successor_id: members.first.id, kind: "sibling")
      members.first.person_relationships.create(family_id: family_id, predecessor_id: members.first.id, successor_id: members.second.id, kind: "sibling")
      missing_relationship -= [rel] #Remove Updated Relation from list of missing relationships
    end

    matrix
  end

  def relationships_complete?
    find_missing_relationships(build_relationship_matrix).present? ? false : true
  end

  def create_dep_consumer_role
    if dependents.any?
      dependents.each do |member|
        build_consumer_role(member)
      end
    end
  end

  def best_verification_due_date
    due_date = contingent_enrolled_family_members_due_dates.detect do |date|
      date > TimeKeeper.date_of_record && (date.to_date.mjd - TimeKeeper.date_of_record.mjd) >= 30
    end
    due_date || contingent_enrolled_family_members_due_dates.last
  end

  def contingent_enrolled_family_members_due_dates
    due_dates = []
    contingent_enrolled_active_family_members.each do |family_member|
      family_member.person.verification_types.active.each do |v_type|
        due_dates << v_type.verif_due_date if VerificationType::DUE_DATE_STATES.include? v_type.validation_status
      end
    end
    due_dates.compact!
    due_dates.uniq.sort
  end

  def min_verification_due_date_on_family
    contingent_enrolled_family_members_due_dates.min.to_date if contingent_enrolled_family_members_due_dates.present?
  end

  def contingent_enrolled_active_family_members
    enrolled_family_members = []
    family_members = active_family_members.collect { |member| member if member.person.is_consumer_role_active? }.compact
    family_members.each do |family_member|
      enrolled_family_members << family_member if enrolled_policy(family_member).present?
    end
    enrolled_family_members
  end

  def document_due_date(v_type)
    (["verified", "attested", "valid"].include? v_type.validation_status) ? nil : v_type.due_date
  end

  def enrolled_policy(family_member)
    enrollments.verification_needed.where(:"hbx_enrollment_members.applicant_id" => family_member.id).first
  end

  def review_status
    if active_household.hbx_enrollments.verification_needed.any?
      active_household.hbx_enrollments.verification_needed.first.review_status
    else
      "no enrollment"
    end
  end

  def person_has_an_active_enrollment?(person)
    active_household.hbx_enrollments.where(:aasm_state.in => HbxEnrollment::ENROLLED_STATUSES).flat_map(&:hbx_enrollment_members).flat_map(&:family_member).flat_map(&:person).include?(person)
  end

  def has_curam_or_mobile_application_type?
    ['Curam', 'Mobile'].include? application_type
  end

  def self.min_verification_due_date_range(start_date,end_date)
    timekeeper_date = TimeKeeper.date_of_record + 95.days
    if timekeeper_date >= start_date.to_date && timekeeper_date <= end_date.to_date
      self.or(:min_verification_due_date => { :"$gte" => start_date, :"$lte" => end_date}).or(:min_verification_due_date => nil)
    else
      self.or(:min_verification_due_date => { :"$gte" => start_date, :"$lte" => end_date})
    end
  end

  def all_persons_vlp_documents_status
    outstanding_types = []
    self.active_family_members.each do |member|
      outstanding_types += member.person.verification_types.active.select{|type| ["outstanding", "pending", "review"].include? type.validation_status }
    end
    fully_uploaded = outstanding_types.any? ? outstanding_types.all?{ |type| (type.type_documents.any? && !type.rejected) } : nil
    partially_uploaded = outstanding_types.any? ? outstanding_types.any?{ |type| (type.type_documents.any? && !type.rejected)} : nil
    if fully_uploaded
      "Fully Uploaded"
    elsif partially_uploaded
      "Partially Uploaded"
    else
      "None"
    end
  end

  def has_active_consumer_family_members
    self.active_family_members.select { |member| member if member.person.consumer_role.present?}
  end

  def has_active_resident_family_members
    self.active_family_members.select { |member| member if member.person.is_resident_role_active? }
  end

  def update_family_document_status!
    update_attributes(vlp_documents_status: self.all_persons_vlp_documents_status)
  end

  def has_valid_e_case_id?
    return false unless e_case_id
    e_case_id.split('#').last.scan(/\D/).empty?
  end

  def set_due_date_on_verification_types(date = nil)
    family_members.each do |family_member|

      person = family_member.person
      person.consumer_role.verification_types.each do |v_type|
        next unless v_type.type_unverified?
        v_type.update_attributes(due_date: date.present? ? date : (TimeKeeper.date_of_record + 95.days),
                                 updated_by: nil,
                                 due_date_type: "notice")
        person.save!
      end
    rescue Exception => e
      puts "Exception in family ID #{family.id}: #{e}" unless Rails.env.test?

    end
  end

  def has_primary_active_employee?
    primary_applicant.person.has_active_employee_role?
  end

  private

  def build_household
    if households.empty?
      irs_group = initialize_irs_group
      initialize_household(irs_group)
    end
  end

  def family_integrity
    only_one_active_primary_family
    single_primary_family_member
    all_family_member_relations_defined
    single_active_household
    no_duplicate_family_members
  end

  def primary_applicant_person
    return nil unless primary_applicant.present?
    primary_applicant.person
  end

  def only_one_active_primary_family
    return unless primary_family_member.present? && primary_family_member.person.present?
    families_with_same_primary = Family.where(
      "family_members" => {
        "$elemMatch" => {
          "is_primary_applicant" => true,
          "person_id" => BSON::ObjectId.from_string(primary_family_member.person_id.to_s)
        }
      },
      "is_active" => true
    )
    self.errors.add(:base, "has another active family with the same primary applicant") if families_with_same_primary.any? { |fam| fam.id.to_s != self.id.to_s }
  end

  def single_primary_family_member
    list = family_members.reduce([]) { |list, family_member| list << family_member if family_member.is_primary_applicant?; list }
    self.errors.add(:family_members, "one family member must be primary family member") if list.empty?
    self.errors.add(:family_members, "may not have more than one primary family member") if list.size > 1
  end

  def all_family_member_relations_defined
    return unless primary_family_member.present? && primary_family_member.person.present?
    primary_member_id = primary_family_member.id
    primary_person = primary_family_member.person
    other_family_members = family_members.select { |fm| (fm.id.to_s != primary_member_id.to_s) && fm.person.present? }
    undefined_relations = other_family_members.any? { |fm| primary_person.find_relationship_with(fm.person).blank? }
    errors.add(:family_members, "relationships between primary_family_member and all family_members must be defined") if undefined_relations
  end

  def find_relationship_between(predecessor, successor)
    predecessor.person_relationships.where(predecessor_id: predecessor.id, successor_id: successor.id, family_id: self.id).first
  end

  def single_active_household
    list = households.reduce([]) { |list, household| list << household if household.is_active?; list }
    self.errors.add(:households, "one household must be active") if list.empty?
    self.errors.add(:households, "may not have more than one active household") if list.size > 1
  end

  def initialize_irs_group
    irs_groups.build(effective_starting_on: TimeKeeper.date_of_record)
  end

  def initialize_household(irs_group)
    households.build(irs_group: irs_group, effective_starting_on: irs_group.effective_starting_on, submitted_at: DateTime.current)
  end

  def no_duplicate_family_members
    family_members.group_by { |appl| appl.person_id }.select { |_k, v| v.size > 1 }.each_pair do |k, v|
      errors.add(:family_members, "Duplicate family_members for person: #{k}\n" \
          "family_members: #{v.inspect}")
    end
  end

  # This method will return true only if all the family_members in tax_household_members and coverage_household_members are present in self.family_members
  def integrity_of_family_member_objects
    return true if self.households.blank?

    family_members_in_family = self.family_members - [nil]
    tax_household_family_members_valid = are_arrays_of_family_members_same?(family_members_in_family.map(&:id), self.households.flat_map(&:tax_households).flat_map(&:tax_household_members).map(&:applicant_id))
    coverage_family_members_valid = are_arrays_of_family_members_same?(family_members_in_family.map(&:id), self.households.flat_map(&:coverage_households).flat_map(&:coverage_household_members).map(&:applicant_id))
    tax_household_family_members_valid && coverage_family_members_valid
  end

  def are_arrays_of_family_members_same?(base_set, test_set)
    base_set.uniq.sort == test_set.uniq.sort
  end

  def reset_active_household(new_household)
    households.each do |household|
      household.is_active = false
    end
    new_household.is_active = true
  end

  def valid_relationship?(family_member)
    return true if primary_applicant.nil? #responsible party case
    return true if primary_applicant.person.id == family_member.person.id

    if IMMEDIATE_FAMILY.include? primary_applicant.person.find_relationship_with(family_member.person)
      true
    else
      false
    end
  end

  def clear_blank_fields
    unset("e_case_id") if e_case_id.blank?
  end
end

# rubocop:enable all

