# frozen_string_literal: true

module FinancialAssistance
  class Applicant # rubocop:disable Metrics/ClassLength TODO: Remove this
    include Mongoid::Document
    include Mongoid::Timestamps
    include AASM
    include Ssn
    include UnsetableSparseFields
    include ActionView::Helpers::TranslationHelper
    include ::L10nHelper
    include Eligibilities::Visitors::Visitable
    include GlobalID::Identification

    embedded_in :application, class_name: "::FinancialAssistance::Application", inverse_of: :applicants

    TAX_FILER_KINDS = %w[tax_filer single joint separate dependent non_filer].freeze
    BULK_REDETERMINATION_ACTION_TYPES = ["Bulk Call", "pvc_bulk_call"].freeze
    STUDENT_KINDS = %w[
      dropped_out
      elementary
      english_language_institute
      full_time
      ged
      graduated
      graduate_school
      half_time
      junior_school
      not_in_school
      open_university
      part_time
      preschool
      primary
      secondary
      technical
      undergraduate
      vocational
      vocational_tech
    ].freeze

    STUDENT_SCHOOL_KINDS = %w[
      english_language_institute
      elementary
      equivalent_vocational_tech
      graduate_school
      ged
      high_school
      junior_school
      open_university
      pre_school
      primary
      technical
      undergraduate
      vocational
    ].freeze
    INCOME_VALIDATION_STATES = %w[na valid outstanding pending].freeze
    MEC_VALIDATION_STATES = %w[na valid outstanding pending].freeze
    CSR_KINDS = ['csr_100', 'csr_94', 'csr_87', 'csr_73', 'csr_0', 'csr_limited'].freeze

    DRIVER_QUESTION_ATTRIBUTES = [
      :has_job_income,
      :has_self_employment_income,
      :has_other_income,
      :has_deductions,
      :has_enrolled_health_coverage,
      :has_eligible_health_coverage
    ] + (
      FinancialAssistanceRegistry[:unemployment_income].enabled? ? [:has_unemployment_income] : []
    ) + (
      FinancialAssistanceRegistry[:american_indian_alaskan_native_income].enabled? ? [:has_american_indian_alaskan_native_income] : []
    ).freeze

    #list of the documents user can provide to verify Immigration status
    VLP_DOCUMENT_KINDS = FinancialAssistanceRegistry[:vlp_documents].setting(:vlp_document_kind_options).item

    CITIZEN_KINDS = {
      us_citizen: "US citizen",
      naturalized_citizen: "Naturalized citizen",
      alien_lawfully_present: "Alien lawfully present",
      lawful_permanent_resident: "Lawful permanent resident",
      undocumented_immigrant: "Undocumented immigrant",
      not_lawfully_present_in_us: "Not lawfully present in US",
      non_native_not_lawfully_present_in_us: "Non-native not lawfully present in US",
      ssn_pass_citizenship_fails_with_SSA: "SSN pass citizenship fails with SSA",
      non_native_citizen: "Non-native citizen"
    }.freeze

    NATURALIZATION_DOCUMENT_TYPES = ["Certificate of Citizenship", "Naturalization Certificate"].freeze

    IMMIGRATION_DOCUMENT_STATUSES = [
      'Member of a Federally Recognized Indian Tribe',
      'Certification from U.S. Department of Health and Human Services (HHS) Office of Refugee Resettlement (ORR)',
      'Office of Refugee Resettlement (ORR) eligibility letter (if under 18)',
      'Cuban/Haitian Entrant',
      'Non Citizen Who Is Lawfully Present In American Samoa',
      'Battered spouse, child, or parent under the Violence Against Women Act',
      'None of these'
    ].freeze

    EVIDENCES = [:income_evidence, :esi_evidence, :non_esi_evidence, :local_mec_evidence].freeze

    NO_SSN_REASONS = {
      "Applicant will provide SSN later": "ApplicantWillProvideSSNLater",
      "Can be issued for non-work reason only": "IssuedForNonWorkReasonOnly",
      "Making best effort to apply": "MakingBestEffortToApply",
      "Newborn without Enumeration at Birth": "NewBornWithoutEnumerationAtBirth",
      "No good cause for not having SSN": "NoGoodCause",
      "No SSN due to religious objections": "ReligiousObjections",
      "Not eligible for SSN": "NotEligible"
    }.freeze

    field :name_pfx, type: String
    field :first_name, type: String
    field :middle_name, type: String
    field :last_name, type: String
    field :name_sfx, type: String
    field :encrypted_ssn, type: String
    field :gender, type: String
    field :dob, type: Date

    field :is_primary_applicant, type: Boolean, default: false

    field :is_incarcerated, type: Boolean
    field :is_disabled, type: Boolean
    field :ethnicity, type: Array
    field :race, type: String
    field :indian_tribe_member, type: Boolean
    field :tribal_id, type: String

    field :language_code, type: String
    field :no_dc_address, type: Boolean, default: false
    field :is_homeless, type: Boolean, default: false
    field :is_temporarily_out_of_state, type: Boolean, default: false
    field :immigration_doc_statuses, type: Array

    field :no_ssn, type: String, default: '0'
    field :citizen_status, type: String
    field :is_consumer_role, type: Boolean
    field :is_resident_role, type: Boolean
    field :same_with_primary, type: Boolean, default: false
    field :is_applying_coverage, type: Boolean
    field :is_tobacco_user, type: String, default: 'unknown'
    field :vlp_document_id, type: String

    field :vlp_subject, type: String
    field :alien_number, type: String
    field :i94_number, type: String
    field :visa_number, type: String
    field :passport_number, type: String
    field :sevis_id, type: String
    field :naturalization_number, type: String
    field :receipt_number, type: String
    field :citizenship_number, type: String
    field :card_number, type: String
    field :country_of_citizenship, type: String
    field :vlp_description, type: String

    # date of expiration of the document. e.g. passport / documentexpiration date
    field :expiration_date, type: DateTime
    # country which issued the document. e.g. passport issuing country
    field :issuing_country, type: String
    # verification type this document can support: Social Security Number, Citizenship, Immigration status, Native American status
    # field :verification_type
    field :is_consent_applicant, type: Boolean, default: false
    field :is_tobacco_user, type: String, default: "unknown"

    field :assisted_income_validation, type: String, default: "pending"
    validates_inclusion_of :assisted_income_validation, :in => INCOME_VALIDATION_STATES, :allow_blank => false
    field :assisted_mec_validation, type: String, default: "pending"
    validates_inclusion_of :assisted_mec_validation, :in => MEC_VALIDATION_STATES, :allow_blank => false
    field :assisted_income_reason, type: String
    field :assisted_mec_reason, type: String

    field :aasm_state, type: String, default: :unverified

    field :person_hbx_id, type: String
    field :ext_app_id, type: String
    field :family_member_id, type: BSON::ObjectId
    field :eligibility_determination_id, type: BSON::ObjectId

    field :is_active, type: Boolean, default: true

    field :has_fixed_address, type: Boolean, default: true
    field :is_living_in_state, type: Boolean, default: false

    field :is_required_to_file_taxes, type: Boolean
    field :is_filing_as_head_of_household, type: Boolean
    field :tax_filer_kind, type: String, default: "tax_filer" # change to the response of is_required_to_file_taxes && is_joint_tax_filing
    field :is_joint_tax_filing, type: Boolean
    field :is_claimed_as_tax_dependent, type: Boolean
    field :claimed_as_tax_dependent_by, type: BSON::ObjectId

    field :is_ia_eligible, type: Boolean, default: false
    field :is_physically_disabled, type: Boolean
    field :is_medicaid_chip_eligible, type: Boolean, default: false
    field :is_non_magi_medicaid_eligible, type: Boolean, default: false
    field :is_totally_ineligible, type: Boolean, default: false
    field :is_without_assistance, type: Boolean, default: false
    field :has_income_verification_response, type: Boolean, default: false
    field :has_mec_verification_response, type: Boolean, default: false

    field :magi_medicaid_monthly_household_income, type: Money, default: 0.00
    field :magi_medicaid_monthly_income_limit, type: Money, default: 0.00

    field :magi_as_percentage_of_fpl, type: Float, default: 0.0
    field :magi_medicaid_type, type: String
    field :magi_medicaid_category, type: String
    field :medicaid_household_size, type: Integer

    field :is_magi_medicaid, type: Boolean, default: false
    field :is_medicare_eligible, type: Boolean, default: false

    field :is_student, type: Boolean
    field :student_kind, type: String
    field :student_school_kind, type: String
    field :student_status_end_on, type: String

    #split this out : change XSD too.
    #field :is_self_attested_blind_or_disabled, type: Boolean, default: false
    field :is_self_attested_blind, type: Boolean
    field :is_self_attested_disabled, type: Boolean, default: false

    field :is_self_attested_long_term_care, type: Boolean, default: false

    field :is_veteran, type: Boolean, default: false
    field :is_refugee, type: Boolean, default: false
    field :is_trafficking_victim, type: Boolean, default: false

    field :is_former_foster_care, type: Boolean
    field :age_left_foster_care, type: Integer, default: 0
    field :foster_care_us_state, type: String
    field :had_medicaid_during_foster_care, type: Boolean

    field :is_pregnant, type: Boolean
    field :is_enrolled_on_medicaid, type: Boolean
    field :is_post_partum_period, type: Boolean
    field :children_expected_count, type: Integer, default: 0
    field :pregnancy_due_on, type: Date
    field :pregnancy_end_on, type: Date

    field :is_primary_caregiver, type: Boolean
    field :is_primary_caregiver_for, type: Array

    field :is_subject_to_five_year_bar, type: Boolean, default: false
    field :is_five_year_bar_met, type: Boolean, default: false
    field :is_forty_quarters, type: Boolean, default: false

    field :is_ssn_applied, type: Boolean
    field :non_ssn_apply_reason, type: String

    # 5 Yr. Bar QNs.
    field :moved_on_or_after_welfare_reformed_law, type: Boolean
    field :is_veteran_or_active_military, type: Boolean
    field :is_spouse_or_dep_child_of_veteran_or_active_military, type: Boolean #remove redundant field
    field :is_currently_enrolled_in_health_plan, type: Boolean

    # Other QNs.
    field :has_daily_living_help, type: Boolean
    field :need_help_paying_bills, type: Boolean
    field :is_resident_post_092296, type: Boolean
    field :is_vets_spouse_or_child, type: Boolean

    field :net_annual_income, type: Money
    # Driver QNs.
    field :has_job_income, type: Boolean
    field :has_self_employment_income, type: Boolean
    field :has_other_income, type: Boolean
    field :has_unemployment_income, type: Boolean
    field :has_deductions, type: Boolean
    field :has_enrolled_health_coverage, type: Boolean
    field :has_eligible_health_coverage, type: Boolean
    field :has_american_indian_alaskan_native_income, type: Boolean

    field :csr_percent_as_integer, type: Integer, default: 0  #values in DC: 0, 73, 87, 94
    field :csr_eligibility_kind, type: String, default: 'csr_0'

    # if eligible immigration status
    field :medicaid_chip_ineligible, type: Boolean
    field :immigration_status_changed, type: Boolean
    # if member of tribe
    field :health_service_through_referral, type: Boolean
    field :health_service_eligible, type: Boolean
    field :tribal_state, type: String
    field :tribal_name, type: String
    field :tribe_codes, type: Array

    field :is_medicaid_cubcare_eligible, type: Boolean

    field :has_eligible_medicaid_cubcare, type: Boolean
    field :medicaid_cubcare_due_on, type: Date
    field :has_eligibility_changed, type: Boolean
    field :has_household_income_changed, type: Boolean
    field :person_coverage_end_on, type: Date

    field :has_dependent_with_coverage, type: Boolean
    field :dependent_job_end_on, type: Date

    field :is_eligible_for_non_magi_reasons, type: Boolean

    field :workflow, type: Hash, default: { }

    field :transfer_referral_reason, type: String

    # Used to store FiveYearBar data that we receive from FDSH Gateway in VLP Response Payload.
    field :five_year_bar_applies, type: Boolean
    field :five_year_bar_met, type: Boolean
    field :qualified_non_citizen, type: Boolean

    embeds_many :verification_types, class_name: "::FinancialAssistance::VerificationType" #, cascade_callbacks: true, validate: true
    embeds_many :incomes,     class_name: "::FinancialAssistance::Income", cascade_callbacks: true, validate: true
    embeds_many :deductions,  class_name: "::FinancialAssistance::Deduction", cascade_callbacks: true, validate: true
    embeds_many :benefits,    class_name: "::FinancialAssistance::Benefit", cascade_callbacks: true, validate: true
    embeds_many :workflow_state_transitions, class_name: "WorkflowStateTransition", as: :transitional
    embeds_many :addresses, cascade_callbacks: true, validate: true, class_name: "::FinancialAssistance::Locations::Address"
    embeds_many :phones, class_name: "::FinancialAssistance::Locations::Phone", cascade_callbacks: true, validate: true
    embeds_many :emails, class_name: "::FinancialAssistance::Locations::Email", cascade_callbacks: true, validate: true
    embeds_one :income_response, class_name: "EventResponse"
    embeds_one :mec_response, class_name: "EventResponse"

    # depricated, need to remove this after after data migration
    embeds_many :evidences,     class_name: "::FinancialAssistance::Evidence"
    # stores eligibility determinations with determination reasons
    embeds_many :member_determinations, class_name: "::FinancialAssistance::MemberDetermination", cascade_callbacks: true

    embeds_one :income_evidence, class_name: "::Eligibilities::Evidence", as: :evidenceable, cascade_callbacks: true
    embeds_one :esi_evidence, class_name: "::Eligibilities::Evidence", as: :evidenceable, cascade_callbacks: true
    embeds_one :non_esi_evidence, class_name: "::Eligibilities::Evidence", as: :evidenceable, cascade_callbacks: true
    embeds_one :local_mec_evidence, class_name: "::Eligibilities::Evidence", as: :evidenceable, cascade_callbacks: true

    accepts_nested_attributes_for :incomes, :deductions, :benefits, :income_evidence, :esi_evidence, :non_esi_evidence, :local_mec_evidence, :member_determinations
    accepts_nested_attributes_for :phones, :reject_if => proc { |addy| addy[:full_phone_number].blank? }, allow_destroy: true
    accepts_nested_attributes_for :addresses, :reject_if => proc { |addy| addy[:address_1].blank? && addy[:city].blank? && addy[:state].blank? && addy[:zip].blank? }, allow_destroy: true
    accepts_nested_attributes_for :emails, :reject_if => proc { |addy| addy[:address].blank? }, allow_destroy: true

    validate :presence_of_attr_step_1, on: [:step_1, :submission]

    validate :presence_of_attr_other_qns, on: :other_qns
    validate :driver_question_responses, on: :submission
    validates :validate_applicant_information, presence: true, on: :submission
    validate :is_temporarily_out_of_state, on: :submission, if: :living_outside_state?

    validate :strictly_boolean

    validates :tax_filer_kind,
              inclusion: { in: TAX_FILER_KINDS, message: "%{value} is not a valid tax filer kind" },
              allow_blank: true

    validates :csr_eligibility_kind,
              allow_blank: false,
              inclusion: { in: CSR_KINDS,
                           message: "%{value} is not a valid cost sharing eligibility kind" }

    alias is_medicare_eligible? is_medicare_eligible
    alias is_joint_tax_filing? is_joint_tax_filing

    # When callback_update is set to true, then both propagate_applicant and propagate_destroy are skipped.
    # This looks weird but this is how it works per implementation.
    attr_accessor :relationship, :callback_update

    # attr_writer :us_citizen, :naturalized_citizen, :indian_tribe_member, :eligible_immigration_status

    before_save :generate_hbx_id

    # Responsible for updating family member  when applicant is created/updated
    after_update :propagate_applicant
    before_destroy :destroy_relationships, :propagate_destroy

    # Scopes
    scope :aptc_eligible,                 -> { where(is_ia_eligible: true) }
    scope :medicaid_or_chip_eligible,     -> { where(is_medicaid_chip_eligible: true) }
    scope :uqhp_eligible,                 -> { where(is_without_assistance: true) } # UQHP, is_without_assistance
    scope :ineligible,                    -> { where(is_totally_ineligible: true) }
    scope :eligible_for_non_magi_reasons, -> { where(is_eligible_for_non_magi_reasons: true) }
    scope :csr_73_87_or_94,               -> { where(:csr_percent_as_integer.in => [94, 87, 73]) }
    scope :csr_100,                       -> { where(csr_percent_as_integer: 100) }
    scope :csr_nal,                       -> { where(csr_percent_as_integer: -1) }
    scope :applying_coverage,             -> { where(is_applying_coverage: true) }

    def generate_hbx_id
      write_attribute(:person_hbx_id, FinancialAssistance::HbxIdGenerator.generate_member_id) if person_hbx_id.blank?
    end

    def accept(visitor)
      visitor.visit(self)
    end

    def csr_percent_as_integer=(new_csr_percent)
      super
      self.csr_eligibility_kind = case csr_percent_as_integer
                                  when 73
                                    'csr_73'
                                  when 87
                                    'csr_87'
                                  when 94
                                    'csr_94'
                                  when 100
                                    'csr_100'
                                  when -1
                                    'csr_limited'
                                  else
                                    'csr_0'
                                  end
    end

    def us_citizen=(val)
      @us_citizen = (val.to_s == "true")
      @naturalized_citizen = false if val.to_s == "false"
    end

    def naturalized_citizen=(val)
      @naturalized_citizen = (val.to_s == "true")
    end

    def eligible_immigration_status=(val)
      @eligible_immigration_status = (val.to_s == "true")
    end

    def us_citizen
      return @us_citizen unless @us_citizen.nil?
      return nil if citizen_status.blank?
      @us_citizen ||= ::ConsumerRole::US_CITIZEN_STATUS_KINDS.include?(citizen_status)
    end

    def naturalized_citizen
      return @naturalized_citizen unless @naturalized_citizen.nil?
      return nil if citizen_status.blank?
      @naturalized_citizen ||= (::ConsumerRole::NATURALIZED_CITIZEN_STATUS == citizen_status)
    end

    def eligible_immigration_status
      return @eligible_immigration_status unless @eligible_immigration_status.nil?
      return nil if us_citizen.nil?
      return nil if @us_citizen
      return nil if citizen_status.blank?
      @eligible_immigration_status ||= (::ConsumerRole::ALIEN_LAWFULLY_PRESENT_STATUS == citizen_status)
    end

    def relationships
      application.relationships.in(applicant_id: id)
    end

    def relatives
      relationships.map(&:relative)
    end

    def relationship=(value)
      return if is_primary_applicant?
      application.ensure_relationship_with_primary(self, value)
    end

    def self.encrypt_ssn(val)
      return nil if val.blank?
      ssn_val = val.to_s.gsub(/\D/, '')
      SymmetricEncryption.encrypt(ssn_val)
    end

    def non_ssn_apply_reason_readable
      if FinancialAssistanceRegistry.feature_enabled?(:no_ssn_reason_dropdown)
        NO_SSN_REASONS.key(self.non_ssn_apply_reason).to_s
      else
        self.non_ssn_apply_reason
      end
    end

    def relation_with_primary
      return 'self' if is_primary_applicant?

      primary_relationship = relationships.in(relative_id: application.primary_applicant.id).first
      primary_relationship&.kind
    end

    def age_on(date)
      age = date.year - dob.year
      if date.month < dob.month || (date.month == dob.month && date.day < dob.day)
        age - 1
      else
        age
      end
    end

    def is_ia_eligible?
      is_ia_eligible && !is_medicaid_chip_eligible && !is_without_assistance && !is_totally_ineligible
    end

    # Checks if applicant is eligible for 73, 87 or 94.
    def is_csr_73_87_or_94?
      is_ia_eligible? && [73, 87, 94].include?(csr_percent_as_integer)
    end

    # Checks if applicant is eligible for 100.
    def is_csr_100?
      is_ia_eligible? && csr_percent_as_integer == 100
    end

    # Checks if applicant is eligible for CSR limited.
    # Applicant is eligible for limited CSR if attested for AI/AN status if csr is not 100,
    # as csr 100 is better than csr limited
    def is_csr_limited?
      (is_ia_eligible? && csr_percent_as_integer == -1) || (indian_tribe_member && csr_percent_as_integer != 100)
    end

    def non_ia_eligible?
      (is_medicaid_chip_eligible || is_without_assistance || is_totally_ineligible) && !is_ia_eligible
    end

    def is_medicaid_chip_eligible?
      is_medicaid_chip_eligible && !is_ia_eligible && !is_without_assistance && !is_totally_ineligible
    end

    def is_tax_dependent?
      tax_filer_kind.present? && tax_filer_kind == "tax_dependent"
    end

    def strictly_boolean
      errors.add(:base, 'is_ia_eligible should be a boolean') unless is_ia_eligible.is_a?(Mongoid::Boolean)
      errors.add(:base, 'is_medicaid_chip_eligible should be a boolean') unless is_medicaid_chip_eligible.is_a?(Mongoid::Boolean)
    end

    def tax_filing?
      is_required_to_file_taxes
    end

    def is_claimed_as_tax_dependent?
      is_claimed_as_tax_dependent
    end

    def is_not_in_a_tax_household?
      eligibility_determination.blank?
    end

    aasm do
      state :unverified, initial: true #Both Income and MEC are Pending.
      state :verification_outstanding #Atleast one of the Verifications is Outstanding.
      state :verification_pending #One of the Verifications is Pending and the other Verification is Verified.
      state :fully_verified #Both Income and MEC are Verified.

      event :income_outstanding, :after => [:record_transition, :change_validation_status, :notify_of_eligibility_change] do
        transitions from: :verification_pending, to: :verification_outstanding
        transitions from: :verification_outstanding, to: :verification_outstanding
      end

      event :mec_outstanding, :after => [:record_transition, :change_validation_status, :notify_of_eligibility_change] do
        transitions from: :verification_pending, to: :verification_outstanding
        transitions from: :verification_outstanding, to: :verification_outstanding
      end

      event :income_valid, :after => [:record_transition, :change_validation_status, :notify_of_eligibility_change] do
        transitions from: :verification_pending, to: :verification_pending, unless: :is_mec_verified?
        transitions from: :verification_pending, to: :fully_verified, :guard => :is_mec_verified?
        transitions from: :verification_outstanding, to: :fully_verified, :guard => :is_mec_verified?
        transitions from: :verification_outstanding, to: :verification_outstanding
        transitions from: :fully_verified, to: :fully_verified
      end

      event :mec_valid, :after => [:record_transition, :change_validation_status, :notify_of_eligibility_change] do
        transitions from: :verification_pending, to: :verification_pending, unless: :is_income_verified?
        transitions from: :verification_pending, to: :fully_verified, :guard => :is_income_verified?
        transitions from: :verification_outstanding, to: :fully_verified, :guard => :is_income_verified?
        transitions from: :verification_outstanding, to: :verification_outstanding
        transitions from: :fully_verified, to: :fully_verified
      end

      event :reject, :after => [:record_transition, :notify_of_eligibility_change] do
        transitions from: :unverified, to: :verification_outstanding
        transitions from: :verification_pending, to: :verification_outstanding
        transitions from: :verification_outstanding, to: :verification_outstanding
        transitions from: :fully_verified, to: :verification_outstanding
      end

      event :move_to_pending, :after => [:record_transition, :notify_of_eligibility_change] do
        transitions from: :unverified, to: :verification_pending
        transitions from: :verification_pending, to: :verification_pending
        transitions from: :verification_outstanding, to: :verification_pending
        transitions from: :fully_verified, to: :verification_pending
      end

      event :move_to_unverified, :after => [:record_transition, :notify_of_eligibility_change] do
        transitions from: :unverified, to: :unverified
        transitions from: :verification_pending, to: :unverified
        transitions from: :verification_outstanding, to: :unverified
        transitions from: :fully_verified, to: :unverified
      end
    end

    #Income/MEC
    def valid_mec_response
      update_attributes!(assisted_mec_validation: "valid")
    end

    def invalid_mec_response
      update_attributes!(assisted_mec_validation: "outstanding")
    end

    def valid_income_response
      update_attributes!(assisted_income_validation: "valid")
    end

    def invalid_income_response
      update_attributes!(assisted_income_validation: "outstanding")
    end

    def family
      application.family || family_member.family
    end

    def spouse_relationship
      application.relationships.where(applicant_id: id, kind: 'spouse').first
    end

    def has_spouse
      spouse_relationship.present?
    end

    def valid_family_relationships?
      valid_spousal_relationship? && valid_child_relationship? && valid_in_law_relationship? && valid_sibling_relationship?
    end

    # Checks that an applicant cannot have more than one spousal relationship
    def valid_spousal_relationship?
      partner_relationships = application.relationships.where({
                                                                "$or" => [
                                                                { :applicant_id => id, :kind.in => ['spouse', 'domestic_partner'] },
                                                                { :relative_id => id, :kind.in => ['spouse', 'domestic_partner'] }
                                                                ]
                                                              })
      return false if partner_relationships.size > 2
      true
    end

    def valid_sibling_relationship?
      sibling_relationships = self.relationships.where(kind: 'sibling')
      return true unless sibling_relationships.present?
      sibling_relationships.each do |sibling_relationship|
        return false unless sibling_relationship.relative.relationships.where(kind: 'sibling').count == sibling_relationships.count
      end
      true
    end

    def valid_child_relationship?
      child_relationship = relationships.where(kind: 'child').first
      return true if child_relationship.blank?

      parent = child_relationship.relative
      domestic_partner_relationship = parent.relationships.where(kind: 'domestic_partner').first
      return true if domestic_partner_relationship.blank?

      ['domestic_partners_child', 'child'].include?(relationships.where(relative_id: domestic_partner_relationship.relative.id).first.kind)
    end

    def valid_in_law_relationship?
      unrelated_relationships = relationships.where(kind: 'unrelated')
      spouse_relationship = relationships.where(:kind => 'spouse').first
      return true unless unrelated_relationships.present? && spouse_relationship.present?
      spouse_sibling_relationships = spouse_relationship.relative.relationships.where(:kind.in => ['sibling', 'brother_or_sister_in_law'])
      return true unless spouse_sibling_relationships.present?

      unrelated_relatives = unrelated_relationships.collect(&:relative_id)
      spouse_siblings = spouse_sibling_relationships.collect(&:relative_id)
      return false if unrelated_relatives.any? { |unrelated_relative| spouse_siblings.include?(unrelated_relative) }
      true
    end

    # Checks to see if there is a relationship for Application where current applicant is spouse to PrimaryApplicant.
    def is_spouse_of_primary
      application.relationships.where(applicant_id: id, kind: 'spouse', relative_id: application.primary_applicant.id).present?
    end

    def eligibility_determination_of_spouse
      return nil unless has_spouse
      spouse_relationship.relative.eligibility_determination
    end

    #### Use Person.consumer_role values for following
    def is_us_citizen?; end

    def is_amerasian?; end

    def is_native_american?; end

    def citizen_status?; end

    def lawfully_present?; end

    def immigration_status?
      person.citizen_status
    end

    def immigration_date?; end

    #### Collect insurance from Benefit model
    def is_enrolled_in_insurance?
      benefits.where(kind: 'is_enrolled').present?
    end

    def is_eligible_for_insurance?
      benefits.where(kind: 'is_eligible').present?
    end

    def had_prior_insurance?; end

    def prior_insurance_end_date; end

    def has_state_health_benefit?
      benefits.where(insurance_kind: 'medicaid').present?
    end

    # Has access to employer-sponsored coverage that meets ACA minimum standard value and
    #   employee responsible premium amount is <= 9.5% of Household income
    def has_employer_sponsored_coverage?
      benefits.where(insurance_kind: 'employer_sponsored_insurance').present?
    end

    def is_without_assistance?
      is_without_assistance
    end

    def has_i327?
      vlp_subject == "I-327 (Reentry Permit)" && alien_number.present?
    end

    def has_i571?
      vlp_subject == 'I-571 (Refugee Travel Document)' && alien_number.present?
    end

    def has_cert_of_citizenship?
      vlp_subject == "Certificate of Citizenship" && citizenship_number.present?
    end

    def has_cert_of_naturalization?
      vlp_subject == "Naturalization Certificate" && naturalization_number.present?
    end

    def has_temp_i551?
      vlp_subject == "Temporary I-551 Stamp (on passport or I-94)" && alien_number.present?
    end

    def has_i94?
      i94_number.present? && (vlp_subject == "I-94 (Arrival/Departure Record)" || (vlp_subject == "I-94 (Arrival/Departure Record) in Unexpired Foreign Passport" && passport_number.present? && expiration_date.present?))
    end

    def has_i20?
      vlp_subject == "I-20 (Certificate of Eligibility for Nonimmigrant (F-1) Student Status)" && sevis_id.present?
    end

    def has_ds2019?
      vlp_subject == "DS2019 (Certificate of Eligibility for Exchange Visitor (J-1) Status)" && sevis_id.present?
    end

    def i551
      vlp_subject == 'I-551 (Permanent Resident Card)' && alien_number.present? && card_number.present?
    end

    def i766
      vlp_subject == 'I-766 (Employment Authorization Card)' && alien_number.present? && card_number.present? && expiration_date.present?
    end

    def mac_read_i551
      vlp_subject == "Machine Readable Immigrant Visa (with Temporary I-551 Language)" && passport_number.present? && alien_number.present?
    end

    def foreign_passport_i94
      vlp_subject == "I-94 (Arrival/Departure Record) in Unexpired Foreign Passport" && i94_number.present? && passport_number.present? && expiration_date.present?
    end

    def foreign_passport
      vlp_subject == "Unexpired Foreign Passport" && passport_number.present? && expiration_date.present?
    end

    def case1
      vlp_subject == "Other (With Alien Number)" && alien_number.present? && vlp_description.present?
    end

    def case2
      vlp_subject == "Other (With I-94 Number)" && i94_number.present? && vlp_description.present?
    end

    def full_name
      @full_name = [name_pfx, first_name, middle_name, last_name, name_sfx].compact.join(" ")
    end

    # Use income entries to determine hours worked
    def total_hours_worked_per_week
      incomes.reduce(0) { |sum_hours, income| sum_hours + income.hours_worked_per_week }
    end

    def tobacco_user
      person.is_tobacco_user || "unknown"
    end

    def eligibility_determination=(eg)
      self.eligibility_determination_id = eg.id
    end

    def eligibility_determination
      return nil unless eligibility_determination_id
      application.eligibility_determinations&.find(eligibility_determination_id)
    end

    def age_on_effective_date
      return @age_on_effective_date unless @age_on_effective_date.blank?
      coverage_start_on = ::Forms::TimeKeeper.new.date_of_record
      return unless coverage_start_on.present?
      age = coverage_start_on.year - dob.year

      # Shave off one year if coverage starts before birthday
      if coverage_start_on.month == dob.month
        age -= 1 if coverage_start_on.day < dob.day
      elsif coverage_start_on.month < dob.month
        age -= 1
      end

      @age_on_effective_date = age
    end

    def contact_addresses
      return addresses if addresses.any? { |address| address.kind == "home" }
      []
    end

    def preferred_eligibility_determination
      eligibility_determination
    end

    # If there is no claimed_as_tax_dependent_by, return true
    # if there is a claimed_as_tax_dependent_by, make sure that the application
    # has an applicant with that id
    def covering_applicant_exists?
      return true if claimed_as_tax_dependent_by.blank?
      tax_claimer_present = application.applicants.where(_id: claimed_as_tax_dependent_by).present?
      errors.add(:base, "Applicant claiming #{self.full_name} as tax dependent not present.") if tax_claimer_present.blank?
      tax_claimer_present
    end

    def applicant_validation_complete?
      if is_applying_coverage
        valid?(:submission) &&
          incomes.all? {|income| income.valid? :submission} &&
          benefits.all? {|benefit| benefit.valid? :submission} &&
          deductions.all? {|deduction| deduction.valid? :submission} &&
          other_questions_complete? &&
          covering_applicant_exists? &&
          ssn_present? &&
          (FinancialAssistanceRegistry.feature_enabled?(:has_medicare_cubcare_eligible) ? medicare_eligible_qns : true)
      else
        valid?(:submission) &&
          incomes.all? {|income| income.valid? :submission} &&
          deductions.all? {|deduction| deduction.valid? :submission} &&
          other_questions_complete? &&
          covering_applicant_exists?
      end
    end

    def clean_conditional_params(model_params)
      clean_params(model_params)
    end

    def age_of_the_applicant
      age_of_applicant
    end

    def format_citizen
      return "" unless citizen_status.present?
      if !is_applying_coverage && citizen_status == "not_lawfully_present_in_us" && FinancialAssistanceRegistry.feature_enabled?(:non_applicant_citizen_status)
        l10n("faa.not_applicable_abbreviation")
      else
        CITIZEN_KINDS[citizen_status.to_sym]
      end
    end

    def student_age_satisfied?
      [18, 19].include? age_of_applicant
    end

    def foster_age_satisfied?
      # Age greater than 18 and less than 26
      (19..25).cover? age_of_applicant
    end

    def other_questions_complete?
      questions_array = []

      questions_array << (non_ssn_apply_reason == "" ? nil : non_ssn_apply_reason) if FinancialAssistanceRegistry.feature_enabled?(:no_ssn_reason_dropdown) && is_ssn_applied == false && is_applying_coverage
      questions_array << is_former_foster_care if foster_age_satisfied? && is_applying_coverage
      questions_array << is_post_partum_period unless is_pregnant
      questions_array << is_physically_disabled if is_applying_coverage && FinancialAssistanceRegistry.feature_enabled?(:question_required)
      questions_array << pregnancy_due_on if is_pregnant && FinancialAssistanceRegistry.feature_enabled?(:pregnancy_due_on_required)
      questions_array << children_expected_count if is_pregnant
      if is_post_partum_period && is_applying_coverage
        questions_array << pregnancy_end_on
        questions_array << is_enrolled_on_medicaid if FinancialAssistanceRegistry.feature_enabled?(:is_enrolled_on_medicaid)
      end

      (other_questions_answers << questions_array).flatten.include?(nil) ? false : true
    end

    def tax_info_complete?
      # is_joint_tax_filing can't be nil for primary or spouse of primary if married and filing taxes
      return false if is_required_to_file_taxes && is_joint_tax_filing.nil? && (is_spouse_of_primary || (is_primary_applicant && has_spouse))
      filing_as_head = (FinancialAssistanceRegistry.feature_enabled?(:filing_as_head_of_household) && is_required_to_file_taxes && is_joint_tax_filing == false && !is_claimed_as_tax_dependent.nil?) ? !is_filing_as_head_of_household.nil? : true
      !is_required_to_file_taxes.nil? &&
        !is_claimed_as_tax_dependent.nil? &&
        filing_as_head
    end

    def tax_info_complete_unmarried_child?
      filing_as_head = (!FinancialAssistanceRegistry.feature_enabled?(:filing_as_head_of_household) && is_required_to_file_taxes && is_joint_tax_filing == false && is_claimed_as_tax_dependent == false)
      !is_required_to_file_taxes.nil? &&
        !is_claimed_as_tax_dependent.nil? &&
        filing_as_head &&
        !is_joint_tax_filing.nil?
    end

    def incomes_complete?
      incomes.all? do |income|
        income.valid? :submission
      end
    end

    def other_incomes_complete?
      incomes.all? do |other_incomes|
        other_incomes.valid? :submission
      end
    end

    def benefits_complete?
      benefits.all? do |benefit|
        benefit.valid? :submission
      end
    end

    def deductions_complete?
      deductions.all? do |deduction|
        deduction.valid? :submission
      end
    end

    def has_income?
      has_job_income || has_self_employment_income || has_other_income
    end

    def relationship_kind_with_primary
      rel = relationships.where(relative_id: application.primary_applicant.id).first
      return "self" if rel.nil?
      rel.kind
    end

    def embedded_document_section_entry_complete?(embedded_document) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity TODO: Remove this
      case embedded_document
      when :income
        return false if has_job_income.nil? || has_self_employment_income.nil?
        return incomes.jobs.present? && job_fields_complete && incomes.self_employment.present? && self_employment_fields_complete if has_job_income && has_self_employment_income
        return incomes.jobs.present? && job_fields_complete && incomes.self_employment.blank? if has_job_income && !has_self_employment_income
        return incomes.jobs.blank? && incomes.self_employment.present? && self_employment_fields_complete if !has_job_income && has_self_employment_income
        incomes.jobs.blank? && incomes.self_employment.blank?
      when :other_income
        return false if FinancialAssistanceRegistry.feature_enabled?(:american_indian_alaskan_native_income) && indian_tribe_member && has_american_indian_alaskan_native_income.nil?

        if FinancialAssistanceRegistry.feature_enabled?(:unemployment_income)
          return false if has_unemployment_income.nil?
          return incomes.unemployment.first.save if incomes.unemployment.count == 1 && has_unemployment_income
          return false if has_unemployment_income.nil? || has_other_income.nil?
          return true if has_unemployment_income == false && has_other_income == false
          return true if has_unemployment_income == true && incomes.unemployment.present? && has_other_income == false
          return true if has_unemployment_income == false && is_other_income_valid?
          return incomes.unemployment.present? && unemployment_fields_complete && incomes.other.present? if incomes.unemployment && incomes.other
          return incomes.unemployment.present? && unemployment_fields_complete && incomes.other.blank? if incomes.unemployment && !incomes.other
          return incomes.unemployment.blank? && unemployment_fields_complete && incomes.other.present? if !incomes.unemployment && incomes.other
          incomes.unemployment.blank? && incomes.other.blank?
          return incomes.unemployment.present? && unemployment_fields_complete if has_unemployment_income
        end
        return false if has_other_income.nil?
        return incomes.other.present? && other_income_fields_complete if has_other_income
        return incomes.other.blank? || incomes.unemployment.blank? if FinancialAssistanceRegistry.feature_enabled?(:unemployment_income)
        incomes.other.blank?
      when :income_adjustment
        return false if has_deductions.nil?
        return deductions.present? && income_adjustment_fields_complete if has_deductions
        deductions.blank?
      when :health_coverage
        return false if indian_tribe_member && health_service_through_referral.nil? && FinancialAssistanceRegistry[:indian_health_service_question].feature.is_enabled
        if FinancialAssistanceRegistry[:medicaid_chip_driver_questions].enabled?
          return false if eligible_immigration_status && medicaid_chip_ineligible.nil?
          return false if eligible_immigration_status && medicaid_chip_ineligible && immigration_status_changed.nil?
        end
        return false if indian_tribe_member && health_service_eligible.nil? && FinancialAssistanceRegistry[:indian_health_service_question].feature.is_enabled
        return medicare_eligible_qns if FinancialAssistanceRegistry.feature_enabled?(:has_medicare_cubcare_eligible)
        return dependent_coverage_questions if FinancialAssistanceRegistry.feature_enabled?(:has_dependent_with_coverage)
        return false if has_enrolled_health_coverage.nil? || has_eligible_health_coverage.nil?
        return benefits.enrolled.present? && benefits.eligible.present? && benefits.all? {|benefit| benefit.valid? :submission} if has_enrolled_health_coverage && has_eligible_health_coverage
        return benefits.enrolled.present? && benefits.enrolled.all? {|benefit| benefit.valid? :submission} && benefits.eligible.blank? if has_enrolled_health_coverage && !has_eligible_health_coverage
        return benefits.enrolled.blank? && benefits.eligible.present? && benefits.eligible.all? {|benefit| benefit.valid? :submission}  if !has_enrolled_health_coverage && has_eligible_health_coverage
        benefits.enrolled.blank? && benefits.eligible.blank?
      end
    end

    def job_fields_complete
      validations = []
      incomes.jobs.select(&:persisted?).each do |job|
        # address = job[:employer_address]
        unless EnrollRegistry[:skip_employer_address_validation].enabled?
          address = job[:employer_address].nil? ? {} : job[:employer_address]
          validations << (address[:address_1].present? && address[:city].present? && address[:state].present? && address[:zip].present?)
        end
        validations << (job[:employer_name].present? && (EnrollRegistry[:skip_employer_address_validation].enabled? ? true : job[:employer_phone].present?))
        validations << (job[:amount].present? && job[:frequency_kind].present? && job[:start_on].present?)
      end
      !validations.include?(false)
    end

    def self_employment_fields_complete
      validations = []
      incomes.self_employment.each do |self_employment|
        validations << (self_employment[:amount].present? && self_employment[:frequency_kind].present? && self_employment[:start_on].present?)
      end
      !validations.include?(false)
    end

    def unemployment_fields_complete
      validations = []
      incomes.unemployment.each do |unemployment|
        validations << (unemployment[:amount].present? && unemployment[:frequency_kind].present? && unemployment[:start_on].present?)
      end
      !validations.include?(false)
    end

    def is_other_income_valid?
      has_other_income == false || (has_other_income == true && incomes.other.present? && other_income_fields_complete)
    end

    def other_income_fields_complete
      validations = []
      incomes.other.each do |other|
        validations << (other[:amount].present? && other[:frequency_kind].present? && other[:start_on].present?)
        validations << other.ssi_type.present? if other.kind == "social_security_benefit" && FinancialAssistanceRegistry.feature_enabled?(:ssi_income_types)
      end
      !validations.include?(false)
    end

    def income_adjustment_fields_complete
      validations = []
      deductions.each do |deduction|
        validations << (deduction[:amount].present? && deduction[:frequency_kind].present? && deduction[:start_on].present?)
      end
      !validations.include?(false)
    end

    def dependent_coverage_questions
      return false if has_dependent_with_coverage.nil?
      return true if has_dependent_with_coverage == false
      return true if has_dependent_with_coverage && dependent_job_end_on.present?
      return false if has_dependent_with_coverage.present? && dependent_job_end_on.blank?
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def medicare_eligible_qns
      return false if has_eligible_medicaid_cubcare.nil?
      return false if has_eligible_medicaid_cubcare.present? && medicaid_cubcare_due_on.blank?
      return true if has_eligible_medicaid_cubcare.present? && medicaid_cubcare_due_on.present?
      return false if has_eligible_medicaid_cubcare == false && has_eligibility_changed.nil?
      return true if has_eligible_medicaid_cubcare == false && has_eligibility_changed == false
      return false if has_eligible_medicaid_cubcare == false && has_eligibility_changed.present? && has_household_income_changed.nil?
      return false if has_eligible_medicaid_cubcare == false && has_eligibility_changed.present? && person_coverage_end_on.blank?
      return true if  has_eligible_medicaid_cubcare == false && has_eligibility_changed.present? && has_household_income_changed == false
      return false if has_eligible_medicaid_cubcare == false && has_eligibility_changed.present? && has_household_income_changed.present? && person_coverage_end_on.blank?
      return true if has_eligible_medicaid_cubcare == false && has_eligibility_changed.present? && has_household_income_changed.present? && person_coverage_end_on.present?
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity

    def assisted_income_verified?
      assisted_income_validation == "valid"
    end

    def assisted_mec_verified?
      assisted_mec_validation == "valid"
    end

    def admin_verification_action(action, v_type, update_reason)
      case action
      when "verify"
        update_verification_type(v_type, update_reason)
      when "return_for_deficiency"
        return_doc_for_deficiency(v_type, update_reason)
      end
    end

    def update_verification_type(v_type, update_reason)
      v_type.update_attributes(validation_status: 'verified', update_reason: update_reason)
      all_types_verified? && !fully_verified? ? verify_ivl_by_admin(v_type) : "#{v_type.type_name} successfully verified."
    end

    def verify_ivl_by_admin(v_type)
      if v_type.type_name == 'Income'
        income_valid!
      else
        mec_valid!
      end
    end

    def all_types_verified?
      verification_types.all?(&:type_verified?)
    end

    def return_doc_for_deficiency(v_type, update_reason)
      v_type.update_attributes(validation_status: 'outstanding', update_reason: update_reason)
      reject!
      "#{v_type.type_name} was rejected"
    end

    def is_assistance_verified?
      !eligible_for_faa? || is_assistance_required_and_verified? ? true : false
    end

    def is_assistance_required_and_verified?
      eligible_for_faa? && income_valid? && mec_valid?
    end

    def income_valid?
      assisted_income_validation == "valid"
    end

    def mec_valid?
      assisted_mec_validation == "valid"
    end

    def eligible_for_faa?
      family.active_approved_application.present?
    end

    def income_pending?
      assisted_doument_pending?("Income")
    end

    def mec_pending?
      assisted_doument_pending?("MEC")
    end

    def income_verification
      verification_types.by_name('Income').first
    end

    def mec_verification
      verification_types.by_name('MEC').first
    end

    def assisted_doument_pending?(kind)
      return true if eligible_for_faa? && verification_types.by_name(kind).present? && verification_types.by_name(kind).first.validation_status == "pending"
      false
    end

    def is_income_verified?
      return true if income_verification.present? && income_verification.validation_status == "verified"
      false
    end

    def is_mec_verified?
      return true if mec_verification.present? && mec_verification.validation_status == 'verified'
      false
    end

    def job_income_exists?
      incomes.jobs.present?
    end

    def self_employment_income_exists?
      incomes.self_employment.present?
    end

    def other_income_exists?
      incomes.other.present?
    end

    def unemployment_income_exists?
      incomes.unemployment.present?
    end

    def american_indian_alaskan_native_income_exists?
      incomes.american_indian_and_alaskan_native.present?
    end

    def deductions_exists?
      deductions.present?
    end

    def enrolled_health_coverage_exists?
      benefits.enrolled.present?
    end

    def eligible_health_coverage_exists?
      benefits.eligible.present?
    end

    def attributes_for_export
      applicant_params = attributes.transform_keys(&:to_sym).slice(:family_member_id,:person_hbx_id,:name_pfx,:first_name,:middle_name,:last_name,:name_sfx,
                                                                   :gender,:is_incarcerated,:is_disabled,:ethnicity,:race,:tribal_id,:language_code,
                                                                   :no_dc_address,:is_homeless,:is_temporarily_out_of_state,:no_ssn,:citizen_status,
                                                                   :is_consumer_role,:vlp_document_id,:is_applying_coverage,:vlp_subject,:alien_number,
                                                                   :i94_number,:visa_number,:passport_number,:sevis_id,:naturalization_number,
                                                                   :receipt_number,:citizenship_number,:card_number,:country_of_citizenship,
                                                                   :issuing_country,:status,:indian_tribe_member,:tribe_codes,
                                                                   :five_year_bar_applies, :five_year_bar_met, :qualified_non_citizen,
                                                                   :same_with_primary,:vlp_description,:tribal_state,:tribal_name)
      applicant_params.merge!({dob: dob.strftime('%d/%m/%Y'), ssn: ssn, relationship: relation_with_primary})
      applicant_params.merge!(expiration_date: expiration_date.strftime('%d/%m/%Y')) if expiration_date.present?
      applicant_params[:addresses] = construct_association_fields(addresses)
      applicant_params[:emails] = construct_association_fields(emails)
      applicant_params[:phones] = construct_association_fields(phones)
      applicant_params
    end

    def construct_association_fields(records)
      records.collect{|record| record.attributes.except(:_id, :created_at, :updated_at) }
    end

    def enrolled_or_eligible_in_any_medicare?
      benefits.any_medicare.present?
    end

    def display_student_question?
      age_of_applicant > 17 && age_of_applicant < 23
    end

    def home_address
      addresses.where(kind: 'home').first
    end

    def current_month_incomes
      month_date_range = TimeKeeper.date_of_record.beginning_of_month..TimeKeeper.date_of_record.end_of_month
      incomes.select do |inc|
        next inc unless application.assistance_year
        end_on = inc.end_on || Date.new(application.assistance_year).end_of_year
        income_date_range = (inc.start_on)..end_on
        date_ranges_overlap?(income_date_range, month_date_range)
      end
    end

    def current_month_earned_incomes
      current_month_incomes.select { |inc| ::FinancialAssistance::Income::EARNED_INCOME_KINDS.include?(inc.kind) }
    end

    def current_month_unearned_incomes
      current_month_incomes.select { |inc| ::FinancialAssistance::Income::UNEARNED_INCOME_KINDS.include?(inc.kind) }
    end

    def create_evidences
      create_evidence(:local_mec, "Local MEC") if FinancialAssistanceRegistry.feature_enabled?(:mec_check)
      create_evidence(:esi_mec, "ESI MEC") if FinancialAssistanceRegistry.feature_enabled?(:esi_mec_determination)
      create_evidence(:non_esi_mec, "Non ESI MEC") if FinancialAssistanceRegistry.feature_enabled?(:non_esi_mec_determination)
    end

    def create_eligibility_income_evidence
      return unless FinancialAssistanceRegistry.feature_enabled?(:ifsv_determination) && income_evidence.blank?

      self.create_income_evidence(key: :income, title: "Income", is_satisfied: true)
      income_evidence.move_to_pending! if incomes.present?
      income_evidence
    end

    def create_evidence(key, title)
      return unless is_ia_eligible? || is_applying_coverage
      association_name = (key == :local_mec) ? key : key.to_s.gsub("_mec", '')
      if self.send("#{association_name}_evidence").blank?
        self.send("create_#{association_name}_evidence", key: key, title: title, is_satisfied: true)
        self.send("#{association_name}_evidence").move_to_pending!
      end
    rescue StandardError => e
      Rails.logger.error("unable to create #{key} evidence for #{self.id} due to #{e.inspect}")
    end

    def update_evidence_histories(assistance_evidences)
      assistance_evidences.each do |evidence_name|
        evidence_record = self.send(evidence_name)
        evidence_record&.add_verification_history('application_determined', 'Requested Hub for verification', 'system')
      end

      self.save
    end

    def create_rrv_evidence_histories(rrv_evidences)
      rrv_evidences.each do |evidence_name|
        evidence_record = self.send(evidence_name)
        evidence_record&.add_verification_history('RRV_Submitted', 'RRV - Renewal verifications submitted', 'system')
      end

      self.save
    rescue StandardError => e
      Rails.logger.error("unable to create rrv evidence histories for #{self.id} due to #{e.inspect}")
    end

    def schedule_verification_due_on
      verification_document_due = EnrollRegistry[:verification_document_due_in_days].item
      TimeKeeper.date_of_record + verification_document_due.days
    end

    def enrolled_with(enrollment)
      EVIDENCES.each do |evidence_type|
        evidence = self.send(evidence_type)
        next unless evidence.present?
        aptc_or_csr_used = enrollment.applied_aptc_amount > 0 || ['02', '04', '05', '06'].include?(enrollment.product.csr_variant_id)

        if aptc_or_csr_used && ['pending', 'negative_response_received'].include?(evidence.aasm_state)
          set_evidence_outstanding(evidence)
        elsif !aptc_or_csr_used
          set_evidence_to_negative_response(evidence)
        elsif evidence.pending?
          set_evidence_unverified(evidence)
        end
      end
    end

    def set_income_evidence_verified
      return unless income_evidence.may_move_to_verified?

      income_evidence.verification_outstanding = false
      income_evidence.due_on = nil
      income_evidence.is_satisfied = true
      income_evidence.move_to_verified
      save!
    end

    # rubocop:disable Naming/AccessorMethodName
    def set_evidence_verified(evidence)
      evidence.verification_outstanding = false
      evidence.is_satisfied = true
      evidence.due_on = nil
      evidence.move_to_verified unless evidence.attested?
      save!
    end

    def set_evidence_attested(evidence)
      evidence.verification_outstanding = false
      evidence.is_satisfied = true
      evidence.due_on = nil
      evidence.attest unless evidence.verified?
      save!
    end

    def set_evidence_outstanding(evidence, desired_due_date = nil)
      return unless evidence.may_move_to_outstanding?

      evidence.verification_outstanding = true
      evidence.is_satisfied = false
      evidence.due_on = (desired_due_date || schedule_verification_due_on) if evidence.due_on.blank?
      evidence.move_to_outstanding
      save!
    end

    def set_evidence_to_negative_response(evidence)
      return unless evidence.may_negative_response_received?

      evidence.verification_outstanding = false
      evidence.is_satisfied = true
      evidence.due_on = nil
      evidence.negative_response_received!
      save!
    end

    def set_evidence_unverified(evidence)
      evidence.verification_outstanding = false
      evidence.is_satisfied = true
      evidence.due_on = nil
      evidence.move_to_unverified
      save!
    end

    def set_evidence_rejected(evidence)
      return unless evidence.may_move_to_rejected?

      evidence.verification_outstanding = true
      evidence.is_satisfied = false
      evidence.move_to_rejected
      save!
    end
    # rubocop:enable Naming/AccessorMethodName

    class << self
      def find(id)
        return nil unless id
        bson_id = BSON::ObjectId.from_string(id.to_s)
        applications = ::FinancialAssistance::Application.where("applicants._id" => bson_id)
        applications.size == 1 ? applications.first.applicants.find(bson_id) : nil
      end
    end

    # Case1: Missing address - No address objects at all
    # Case2: Invalid Address - No addresses matching the state (unless out_of_state_primary feature is enabled)
    # Case3: Unable to get rating area(home_address || mailing_address)
    def has_valid_address?
      if FinancialAssistanceRegistry.feature_enabled?(:out_of_state_primary)
        addresses.where(
          :kind.in => ['home', 'mailing']
        ).present?
      else
        addresses.where(
          state: FinancialAssistanceRegistry[:enroll_app].setting(:state_abbreviation).item,
          :kind.in => ['home', 'mailing']
        ).present?
      end
    end

    #use this method to check what evidences needs to be included on notices
    def unverified_evidences
      evidences.find_all(&:type_unverified?)
    end

    def ssn_present?
      errors.add(:base, 'no ssn present.') if no_ssn == '0' && ssn.blank?
      return false if no_ssn == '0' && ssn.blank?
      true
    end

    def build_new_email(email_params)
      emails.build(email_params)
    end

    def build_new_phone(phone_params)
      phones.build(phone_params)
    end

    def build_new_address(address_params)
      addresses.build(address_params)
    end

    def clone_evidences(new_applicant)
      clone_income_evidence(new_applicant) if income_evidence.present?
      clone_esi_evidence(new_applicant) if esi_evidence.present?
      clone_non_esi_evidence(new_applicant) if non_esi_evidence.present?
      clone_local_mec_evidence(new_applicant) if local_mec_evidence.present?
    end

    def is_dependent?
      !is_primary_applicant?
    end

    # Returns the first mailing address of the applicant.
    #
    # @return [Address, nil] the first mailing address if one exists, otherwise nil
    def mailing_address
      addresses.mailing.first
    end

    # Fetches the evidence based on the provided evidence type.
    #
    # This method accepts an evidence type as a parameter and returns the corresponding evidence.
    # The evidence type can be one of the following: 'income_evidence', 'esi_evidence', 'non_esi_evidence', or 'local_mec_evidence'.
    #
    # @param evidence_type [String] The type of evidence to fetch.
    # @return [Object] The evidence corresponding to the provided type.
    def fetch_evidence(evidence_type)
      case evidence_type
      when 'income_evidence'
        income_evidence
      when 'esi_evidence'
        esi_evidence
      when 'non_esi_evidence'
        non_esi_evidence
      when 'local_mec_evidence'
        local_mec_evidence
      end
    end

    private

    def fetch_evidence_params(evidence)
      evidence.attributes.deep_symbolize_keys.slice(:key, :title, :description, :received_at, :is_satisfied, :verification_outstanding, :aasm_state, :update_reason, :due_on, :external_service, :updated_by)
    end

    def clone_income_evidence(new_applicant)
      params = fetch_evidence_params(income_evidence)
      new_income_evi = new_applicant.build_income_evidence(params)
      income_evidence.clone_embedded_documents(new_income_evi)
    end

    def clone_esi_evidence(new_applicant)
      new_esi_evi = new_applicant.build_esi_evidence(fetch_evidence_params(esi_evidence))
      esi_evidence.clone_embedded_documents(new_esi_evi)
    end

    def clone_non_esi_evidence(new_applicant)
      new_non_esi_evi = new_applicant.build_non_esi_evidence(fetch_evidence_params(non_esi_evidence))
      non_esi_evidence.clone_embedded_documents(new_non_esi_evi)
    end

    def clone_local_mec_evidence(new_applicant)
      new_local_mec_evi = new_applicant.build_local_mec_evidence(fetch_evidence_params(local_mec_evidence))
      local_mec_evidence.clone_embedded_documents(new_local_mec_evi)
    end

    def date_ranges_overlap?(range_a, range_b)
      range_b.begin <= range_a.end && range_a.begin <= range_b.end
    end

    def change_validation_status
      kind = aasm.current_event.to_s.include?('income') ? 'Income' : 'MEC'
      status = aasm.current_event.to_s.include?('outstanding') ? 'outstanding' : 'verified'
      verification_types.by_name(kind).first.update_attributes!(validation_status: status)
    end

    def other_questions_answers
      if is_applying_coverage
        [:is_ssn_applied].inject([]) do |array, question|
          no_ssn_flag = no_ssn

          array << send(question) if question != :is_ssn_applied || (question == :is_ssn_applied && no_ssn_flag == '1')
          array
        end
      else
        is_pregnant ? [is_pregnant] : [is_post_partum_period]
      end
    end

    def validate_applicant_information
      validates_presence_of :has_fixed_address, :is_claimed_as_tax_dependent, :is_living_in_state, :is_pregnant
    end

    def living_outside_state?
      EnrollRegistry.feature_enabled?(:living_outside_state)
    end

    def driver_question_responses
      DRIVER_QUESTION_ATTRIBUTES.each do |attribute|
        next if attribute == :has_american_indian_alaskan_native_income && !indian_tribe_member
        next if [:has_enrolled_health_coverage, :has_eligible_health_coverage].include?(attribute) && !is_applying_coverage

        instance_type = attribute.to_s.gsub('has_', '')
        instance_check_method = "#{instance_type}_exists?"

        # Add error to attribute that has a nil value.
        errors.add(attribute, "#{attribute.to_s.titleize} can not be a nil") if send(attribute).nil?

        # Add base error when driver question has a 'Yes' value and there is No existing instance for that type.
        if send(attribute) && !public_send(instance_check_method)
          errors.add(:base, "Based on your response, you should have at least one #{instance_type.titleize}.
                             Please correct your response to '#{attribute}', or add #{instance_type.titleize}.")
        end

        # Add base error when driver question has a 'No' value and there is an existing instance for that type.

        # TODO: Commenting below validations until Demo. Should fix POST DEMO!!!
        # if !send(attribute) && public_send(instance_check_method)
        #   errors.add(:base, "Based on your response, you should have no instance of #{instance_type.titleize}.
        #                      Please correct your response to '#{attribute}', or delete the existing #{instance_type.titleize}.")
        # end
      end
    end

    def presence_of_attr_step_1
      errors.add(:is_joint_tax_filing, "#{full_name} must answer 'Will this person be filing jointly?'") if is_required_to_file_taxes && is_joint_tax_filing.nil? && (is_spouse_of_primary || (is_primary_applicant && has_spouse))
      errors.add(:claimed_as_tax_dependent_by, "' This person will be claimed as a dependent by' can't be blank") if is_claimed_as_tax_dependent && claimed_as_tax_dependent_by.nil?
      errors.add(:is_required_to_file_taxes, "' is_required_to_file_taxes can't be blank") if is_required_to_file_taxes.nil?
      errors.add(:is_claimed_as_tax_dependent, "' is_claimed_as_tax_dependent can't be blank") if is_claimed_as_tax_dependent.nil?
    end

    def presence_of_attr_other_qns # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity TODO: Remove this
      if is_pregnant
        errors.add(:pregnancy_due_on, "' Pregnancy Due date' should be answered if you are pregnant") if pregnancy_due_on.blank? && FinancialAssistanceRegistry.feature_enabled?(:pregnancy_due_on_required)
        errors.add(:pregnancy_due_on,"' Pregnancy Due date' should be in the future") if pregnancy_due_on.present? && pregnancy_due_on < TimeKeeper.date_of_record
        errors.add(:children_expected_count, "' How many children is this person expecting?' should be answered") if children_expected_count.blank?
      # Nil or "" means unanswered, true/or false boolean will be passed through
      elsif is_post_partum_period.nil? || is_post_partum_period == ""
        if FinancialAssistanceRegistry.feature_enabled?(:post_partum_period_one_year)
          errors.add(:is_post_partum_period, "'#{l10n('faa.other_ques.pregnant_last_year')}' should be answered")
        else
          # Even if they aren't pregnant, still need to ask if they were pregnant within the last 60 days
          errors.add(:is_post_partum_period, "'#{l10n('faa.other_ques.pregnant_last_60d')}' should be answered")
        end
      end
      # If they're in post partum period, they need to tell us if they were on medicaid and when the pregnancy ended
      if is_post_partum_period.present?
        # Enrolled on medicaid must check if nil
        is_enrolled_on_medicaid_not_answered = is_enrolled_on_medicaid.nil? && is_applying_coverage && FinancialAssistanceRegistry.feature_enabled?(:is_enrolled_on_medicaid)
        errors.add(:is_enrolled_on_medicaid, "'#{l10n('faa.other_ques.is_enrolled_on_medicaid')}' #{l10n('faa.errors.should_be_answered')}") if is_enrolled_on_medicaid_not_answered
        errors.add(:pregnancy_end_on, "' Pregnancy End on date' should be answered") if pregnancy_end_on.blank?
      end

      if FinancialAssistanceRegistry.feature_enabled?(:primary_caregiver_other_question) && age_of_applicant >= 19 && is_applying_coverage == true && is_primary_caregiver.nil?
        errors.add(:is_primary_caregiver, "'#{l10n('faa.primary_caretaker_question_text')}' should be answered")
      end

      return unless is_applying_coverage

      if age_of_applicant > 18 && age_of_applicant < 26
        errors.add(:is_former_foster_care, "' Was this person in foster care at age 18 or older?' should be answered") if is_former_foster_care.nil?

        if is_former_foster_care
          errors.add(:foster_care_us_state, "' Where was this person in foster care?' should be answered") if foster_care_us_state.blank?
          errors.add(:age_left_foster_care, "' How old was this person when they left foster care?' should be answered") if age_left_foster_care.nil?
        end
      end

      if is_student && FinancialAssistanceRegistry.feature_enabled?(:student_follow_up_questions)
        errors.add(:student_kind, "' #{l10n('faa.other_ques.is_student')}' should be answered") if student_kind.blank?
        errors.add(:student_status_end_on, "' Student status end on date?'  should be answered") if student_status_end_on.blank?
        errors.add(:student_school_kind, "' What type of school do you go to?' should be answered") if student_school_kind.blank?
      end

      errors.add(:is_student, "' #{l10n('faa.other_ques.is_student')}' should be answered") if age_of_applicant.between?(18,19) && is_student.nil?
      # TODO: Decide if these validations should be ended?
      # errors.add(:claimed_as_tax_dependent_by, "' This person will be claimed as a dependent by' can't be blank") if is_claimed_as_tax_dependent && claimed_as_tax_dependent_by.nil?

      # errors.add(:is_required_to_file_taxes, "' is_required_to_file_taxes can't be blank") if is_required_to_file_taxes.nil?
    end

    def age_of_applicant
      age_on(TimeKeeper.date_of_record)
    end

    def clean_params(model_params) # rubocop:disable Metrics/CyclomaticComplexity TODO: Remove this
      model_params[:is_joint_tax_filing] = nil if model_params[:is_required_to_file_taxes].present? && model_params[:is_required_to_file_taxes] == 'false'

      model_params[:claimed_as_tax_dependent_by] = nil if model_params[:is_claimed_as_tax_dependent].present? && model_params[:is_claimed_as_tax_dependent] == 'false'

      # TODO : Revise this logic for conditional saving!
      if model_params[:is_pregnant].present? && model_params[:is_pregnant] == 'false'
        model_params[:pregnancy_due_on] = nil
        model_params[:children_expected_count] = nil
        model_params[:is_enrolled_on_medicaid] = nil if model_params[:is_post_partum_period] == "false"
      end

      if model_params[:is_pregnant].present? && model_params[:is_pregnant] == 'true'
        model_params[:is_post_partum_period] = nil
        model_params[:pregnancy_end_on] = nil
        model_params[:is_enrolled_on_medicaid] = nil
      end

      if model_params[:is_former_foster_care].present? && model_params[:is_former_foster_care] == 'false'
        model_params[:foster_care_us_state] = nil
        model_params[:age_left_foster_care] = nil
        model_params[:had_medicaid_during_foster_care] = nil
      end

      return unless model_params[:is_student].present? && model_params[:is_student] == 'false'
      model_params[:student_kind] = nil
      model_params[:student_status_end_on] = nil
      model_params[:student_kind] = nil
    end

    def record_transition
      workflow_state_transitions << WorkflowStateTransition.new(
        from_state: aasm.from_state,
        to_state: aasm.to_state,
        event: aasm.current_event,
        user_id: SAVEUSER[:current_user_id]
      )
    end

    #Income/MEC Verifications
    def notify_of_eligibility_change
      # CoverageHousehold.update_eligibility_for_family(family)
    end

    # Changes should flow to Main App only when application is in draft state.
    def propagate_applicant
      # return if incomes_changed? || benefits_changed? || deductions_changed?
      return unless application.draft?
      if is_active && !callback_update
        create_or_update_member_params = { applicant_params: self.attributes_for_export, family_id: application.family_id }
        create_or_update_result = if FinancialAssistanceRegistry[:avoid_dup_hub_calls_on_applicant_create_or_update].enabled?
                                    create_or_update_member_params[:applicant_params].merge!(is_primary_applicant: is_primary_applicant?, skip_consumer_role_callbacks: true, skip_person_updated_event_callback: true)
                                    ::Operations::Families::CreateOrUpdateMember.new.call(create_or_update_member_params)
                                  else
                                    ::FinancialAssistance::Operations::Families::CreateOrUpdateMember.new.call(params: create_or_update_member_params)
                                  end
        if create_or_update_result.success?
          response_family_member_id = create_or_update_result.success[:family_member_id]
          update_attributes!(family_member_id: response_family_member_id) if family_member_id.nil?
        else
          Rails.logger.error {"Unable to propagate_applicant for person hbx_id: #{self.person_hbx_id} | application_hbx_id: #{application.hbx_id} | family_id: #{application.family_id} due to #{create_or_update_result.failure}"} unless Rails.env.test?
        end
        application.update_dependents_home_address if is_primary_applicant? && address_info_changed?
      end
    rescue StandardError => e
      Rails.logger.error {"Unable to propagate_applicant for person hbx_id: #{self.person_hbx_id} | application_hbx_id: #{application.hbx_id} | family_id: #{application.family_id} due to #{e.message}"} unless Rails.env.test?
    end

    def address_info_changed?
      home_address.changed? || no_dc_address_changed? || is_homeless_changed? || is_temporarily_out_of_state_changed?
    end

    # Changes should flow to Main App only when application is in draft state.
    def propagate_destroy
      return unless application.draft?
      return if callback_update
      delete_params = {:family_id => application.family_id, :person_hbx_id => person_hbx_id}
      ::Operations::Families::DropFamilyMember.new.call(delete_params)

      Success('A successful call was made to enroll to drop a family member')
    rescue StandardError => e
      e.message
    end

    def destroy_relationships
      application.relationships.where(applicant_id: self.id).destroy_all
      application.relationships.where(relative_id: self.id).destroy_all
    end
  end
end
