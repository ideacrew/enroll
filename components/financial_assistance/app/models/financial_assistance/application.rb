# frozen_string_literal: true

module FinancialAssistance
  class Application # rubocop:disable Metrics/ClassLength TODO: Remove this

    include Mongoid::Document
    include Mongoid::Timestamps
    include AASM
    include Acapi::Notifiers
    require 'securerandom'
    include Eligibilities::Visitors::Visitable
    include GlobalID::Identification
    include I18n
    include Transmittable::Subject

    # belongs_to :family, class_name: "Family"

    before_create :set_hbx_id, :set_applicant_kind, :set_request_kind, :set_motivation_kind, :set_us_state, :set_is_ridp_verified, :set_external_identifiers
    validate :application_submission_validity, on: :submission
    validate :before_attestation_validity, on: :before_attestation
    validate :attestation_terms_on_parent_living_out_of_home

    YEARS_TO_RENEW_RANGE = (0..5).freeze

    # Max of this range is set as below because during OE the user can authorize state to renew for up to 5 years from the assistance_year.
    # Example:
    #   On 11/15/2021(during OE), user can submit application for 2022 and can authorize renewal for next 5 years i.e. 2022 + 5
    RENEWAL_BASE_YEAR_RANGE = (2013..TimeKeeper.date_of_record.year.next + YEARS_TO_RENEW_RANGE.max).freeze

    APPLICANT_KINDS   = ["user and/or family", "call center rep or case worker", "authorized representative"].freeze
    SOURCE_KINDS      = %w[paper source in-person].freeze
    REQUEST_KINDS     = %w[].freeze
    MOTIVATION_KINDS  = %w[insurance_affordability].freeze

    SUBMITTED_STATUS = %w[submitted verifying_income].freeze
    REVIEWABLE_STATUSES = %w[submitted determination_response_error determined terminated].freeze
    CLOSED_STATUSES = %w[cancelled terminated].freeze

    STATES_FOR_VERIFICATIONS = %w[submitted determination_response_error determined].freeze

    RENEWAL_ELIGIBLE_STATES = %w[submitted determined imported].freeze

    SAFE_REGISTRY_METHODS = {
      "FinancialAssistance::Operations::EnrollmentDates::EarliestEffectiveDate" => FinancialAssistance::Operations::EnrollmentDates::EarliestEffectiveDate,
      "FinancialAssistance::Operations::EnrollmentDates::ApplicationYear" => FinancialAssistance::Operations::EnrollmentDates::ApplicationYear
    }.freeze

    # TODO: Need enterprise ID assignment call for Assisted Application
    field :hbx_id, type: String

    ## Remove after data Cleanup ##
    field :external_id, type: String
    field :integrated_case_id, type: String
    ##
    field :family_id, type: BSON::ObjectId

    field :haven_app_id, type: String
    field :haven_ic_id, type: String
    field :e_case_id, type: String

    field :applicant_kind, type: String

    field :request_kind, type: String
    field :motivation_kind, type: String

    field :is_joint_tax_filing, type: Boolean
    field :eligibility_determination_id, type: BSON::ObjectId

    field :aasm_state, type: String, default: :draft
    field :submitted_at, type: DateTime
    field :effective_date, type: DateTime # Date they want coverage
    field :timeout_response_last_submitted_at, type: DateTime

    # The `assistance_year` of an application gets set during the submission of an application.
    # Use `FinancialAssistanceRegistry[:application_year].item.call.value!` method in the Family model incase you need `assistance_year`
    # when aplication is in a `draft state`.
    field :assistance_year, type: Integer

    field :is_renewal_authorized, type: Boolean, default: true
    field :renewal_base_year, type: Integer
    field :years_to_renew, type: Integer

    field :is_requesting_voter_registration_application_in_mail, type: Boolean

    field :us_state, type: String
    field :benchmark_product_id, type: BSON::ObjectId

    field :medicaid_terms, type: Boolean
    field :medicaid_insurance_collection_terms, type: Boolean
    field :report_change_terms, type: Boolean
    field :parent_living_out_of_home_terms, type: Boolean
    field :attestation_terms, type: Boolean
    field :submission_terms, type: Boolean

    field :request_full_determination, type: Boolean
    field :integrated_case_id, type: String

    field :is_ridp_verified, type: Boolean
    field :determination_http_status_code, type: Integer
    field :determination_error_message, type: String
    field :has_eligibility_response, type: Boolean, default: false
    field :eligibility_request_payload, type: String
    field :eligibility_response_payload, type: String
    field :full_medicaid_determination, type: Boolean
    field :workflow, type: Hash, default: { }

    # predecessor_id is the application id of the application which was renewed
    # predecessor_id is populated if the new application is system generated renewal
    # predecessor_id is the application preceding this current application
    field :predecessor_id, type: BSON::ObjectId

    # Flag for user requested ATP transfer
    field :transfer_requested, type: Boolean, default: false
    # Account was transferred to medicaid service via atp
    field :account_transferred, type: Boolean, default: false
    field :transferred_at, type: DateTime #time account was transfered in or out of Enroll (when batch process completes)

    # Transfer ID of to be set if the application was transferred into Enroll via ATP
    field :transfer_id, type: String

    field :has_mec_check_response, type: Boolean, default: false

    # A field to store reasons why an application cannot be put into the "renewal_draft" state without a user input.
    # This is only applicable in application renewals context.
    # The value of this field is only valid if the application is either in 'applicants_update_required' or 'income_verification_extension_required' state.
    field :renewal_draft_blocker_reasons, type: Array

    embeds_many :eligibility_determinations, inverse_of: :application, class_name: '::FinancialAssistance::EligibilityDetermination', cascade_callbacks: true, validate: true
    embeds_many :relationships, inverse_of: :application, class_name: '::FinancialAssistance::Relationship', cascade_callbacks: true, validate: true
    embeds_many :applicants, inverse_of: :application, class_name: '::FinancialAssistance::Applicant', cascade_callbacks: true, validate: true
    embeds_many :workflow_state_transitions, class_name: "WorkflowStateTransition", as: :transitional

    accepts_nested_attributes_for :applicants, :workflow_state_transitions

    # validates_presence_of :hbx_id, :applicant_kind, :request_kind, :benchmark_product_id

    # User must agree with terms of service check boxes
    # validates_acceptance_of :medicaid_terms, :attestation_terms, :submission_terms

    validates :renewal_base_year, allow_nil: true,
                                  numericality: {
                                    only_integer: true,
                                    greater_than_or_equal_to: RENEWAL_BASE_YEAR_RANGE.first,
                                    less_than_or_equal_to: RENEWAL_BASE_YEAR_RANGE.last,
                                    message: "must fall within range: #{RENEWAL_BASE_YEAR_RANGE}"
                                  }

    validates :years_to_renew,    allow_nil: true,
                                  numericality: {
                                    only_integer: true,
                                    greater_than_or_equal_to: YEARS_TO_RENEW_RANGE.first,
                                    less_than_or_equal_to: YEARS_TO_RENEW_RANGE.last,
                                    message: "must fall within range: #{YEARS_TO_RENEW_RANGE}"
                                  }

    index({"is_renewal_authorized" => 1})
    index({"family_id" => 1})
    index({"benchmark_product_id" => 1})
    index({"has_eligibility_response" => 1})
    index({"applicant_kind" => 1})
    index({"has_mec_check_response" => 1})

    index({ renewal_draft_blocker_reasons: 1 })

    index({ hbx_id: 1 })
    index({ aasm_state: 1 })
    index({ created_at: 1 })
    index({ assistance_year: 1 })
    index({ aasm_state: 1, submitted_at: 1 })
    index({ aasm_state: 1, family_id: 1 })
    index({ "workflow_state_transitions.transition_at" => 1,
            "workflow_state_transitions.to_state" => 1 },
          { name: "workflow_to_state" })

    index({"relationships._id" => 1 })
    index({"relationships.applicant_id" => 1})
    index({"relationships.relative_id" => 1})
    index({"relationships.kind" => 1})

    index({"eligibility_determinations._id" => 1})
    index({"eligibility_determinations.max_aptc" => 1})
    index({"eligibility_determinations.csr_percent_as_integer" => 1})
    index({"eligibility_determinations.source" => 1})
    index({"eligibility_determinations.effective_starting_on" => 1})
    index({"eligibility_determinations.effective_ending_on" => 1})
    index({"eligibility_determinations.is_eligibility_determined" => 1})
    index({"eligibility_determinations.hbx_assigned_id" => 1})
    index({"eligibility_determinations.determined_at" => 1})

    # applicant index
    index({ "applicants._id" => 1 })
    index({"applicants.no_ssn" => 1})
    index({"applicants.aasm_state" => 1})
    index({"applicants.is_active" => 1})
    index({"applicants.csr_percent_as_integer" => 1})
    index({"applicants.csr_eligibility_kind" => 1})

    index({"applicants.is_primary_applicant" => 1})

    # verification_types index
    index({"applicants.verification_types._id" => 1})
    index({"applicants.verification_types.type_name" => 1})
    index({"applicants.verification_types.validation_status" => 1})
    index({"applicants.verification_types.update_reason" => 1})
    index({"applicants.verification_types.rejected" => 1})
    index({"applicants.verification_types.external_service" => 1})
    index({"applicants.verification_types.due_date" => 1})
    index({"applicants.verification_types.due_date_type" => 1})

    # incomes index
    index({"applicants.incomes._id" => 1})
    index({"applicants.incomes.kind" => 1})

    # deduction index
    index({"applicants.deductions._id" => 1})
    index({"applicants.deductions.kind" => 1})

    # benefit index
    index({"applicants.benefits._id" => 1})
    index({"applicants.benefits.kind" => 1})
    index({"applicants.benefits.esi_covered" => 1})
    index({"applicants.benefits.insurance_kind" => 1})
    index({"applicants.benefits.is_employer_sponsored" => 1})

    index({"applicants.benefits.start_on" => 1})
    index({"applicants.benefits.end_on" => 1})
    index({"applicants.benefits.submitted_at" => 1})
    index({"applicants.benefits.employer_id" => 1})

    index({"applicants.evidences.eligibility_status" => 1})

    # Applicant evidences
    index({ "applicants.income_evidence.aasm_state" => 1 })
    index({ "applicants.esi_evidence.aasm_state" => 1 })
    index({ "applicants.non_esi_evidence.aasm_state" => 1 })
    index({ "applicants.local_mec_evidence.aasm_state" => 1 })

    scope :submitted, ->{ any_in(aasm_state: SUBMITTED_STATUS) }
    scope :determined, ->{ any_in(aasm_state: "determined") }
    scope :closed, ->{ any_in(aasm_state: CLOSED_STATUSES) }
    scope :by_hbx_id, ->(hbx_id) { where(hbx_id: hbx_id) }
    scope :for_verifications, -> { where(:aasm_state.in => STATES_FOR_VERIFICATIONS)}
    scope :by_year, ->(year) { where(:assistance_year => year) }
    scope :created_asc,      -> { order(created_at: :asc) }
    scope :renewal_draft,    ->{ any_in(aasm_state: 'renewal_draft') }
    scope :income_verification_extension_required, ->{ any_in(aasm_state: 'income_verification_extension_required') }
    scope :determined_and_submitted_within_range, lambda { |range|
      where(aasm_state: 'determined', submitted_at: range)
    }
    scope :for_determined_family, lambda { |family_id|
      where(aasm_state: 'determined', family_id: family_id)
    }

    # Applications that are in submitted and after submission states. Non work in progress applications.
    scope :submitted_and_after, lambda {
      where(
        :aasm_state.in => ['submitted',
                           'mitc_magi_medicaid_eligibility_request_errored',
                           'haven_magi_medicaid_eligibility_request_errored',
                           'determination_response_error',
                           'determined',
                           'imported']
      )
    }

    scope :renewal_eligible, -> { where(:aasm_state.in => RENEWAL_ELIGIBLE_STATES) }

    scope :has_outstanding_verifications, -> { where(:"applicants.evidences.eligibility_status".in => ["outstanding", "in_review"]) }

    scope :with_renewal_blocker_reasons, -> { where(:renewal_draft_blocker_reasons.ne => nil, :aasm_state.in => ['applicants_update_required', 'income_verification_extension_required']) }

    alias is_joint_tax_filing? is_joint_tax_filing
    alias is_renewal_authorized? is_renewal_authorized

    def ensure_relationship_with_primary(applicant, relation_kind)
      add_or_update_relationships(applicant, primary_applicant, relation_kind)
    end

    def self.families_with_latest_determined_outstanding_verification
      states = ["outstanding", "in_review"]
      application_ids = FinancialAssistance::Application.order_by(created_at: :asc).collection.aggregate([
        {"$match" => {"aasm_state" => "determined"}},
        {"$sort" => {"family_id" => 1}},
        {
          "$group" => {
            "_id" => "$family_id",
            "application_id" => {"$last" => "$_id"}
          }
        }
      ],{allow_disk_use: true}).collect {|iap| iap["application_id"]}

      FinancialAssistance::Application.where(:_id.in => application_ids,
                                             :aasm_state => "determined",
                                             :"applicants.is_active" => true,
                                             :"applicants.evidences.eligibility_status".in => states)
    end

    # Creates both relationships A to B, and B to A.
    # This way we do not have to call two methods to create relationships
    def add_or_update_relationships(applicant, applicant2, relation_kind)
      update_or_build_relationship(applicant, applicant2, relation_kind)
      inverse_relationship_kind = ::FinancialAssistance::Relationship::INVERSE_MAP[relation_kind]
      update_or_build_relationship(applicant2, applicant, inverse_relationship_kind) if inverse_relationship_kind.present?
    end

    def update_or_build_relationship(applicant, relative, relation_kind)
      return if applicant.blank? || relative.blank? || relation_kind.blank?
      return if applicant == relative

      relationship = relationships.where(applicant_id: applicant.id, relative_id: relative.id).first
      if relationship.present?
        # Update relationship object only if the existing RelationshipKind is different from the incoming RelationshipKind.
        relationship.update(kind: relation_kind) if relationship.kind != relation_kind
      else
        self.relationships << ::FinancialAssistance::Relationship.new(
          {
            kind: relation_kind,
            applicant_id: applicant.id,
            relative_id: relative.id
          }
        )
      end
    end

    def accept(visitor)
      applicants.collect{|applicant| applicant.accept(visitor) }
    end

    # Related to Relationship Matrix
    def add_relationship(predecessor, successor, relationship_kind, destroy_relation = false)
      self.reload
      direct_relationship = relationships.where(applicant_id: predecessor.id, relative_id: successor.id).first # Direct Relationship
      return if direct_relationship.present? && direct_relationship.kind == relationship_kind

      if direct_relationship.present?
        # Destroying the relationships associated to the Person other than the new updated relationship.
        if destroy_relation
          predecessor_rels_except_current = relationships.where(applicant_id: predecessor.id, :id.ne => direct_relationship.id)
          predecessor_relationships_relative_ids = predecessor_rels_except_current.pluck(:relative_id)
          predecessor_rels_except_current.destroy_all
          relationships.where(:applicant_id.in => predecessor_relationships_relative_ids, relative_id: predecessor.id).destroy_all
        end

        direct_relationship.update(kind: relationship_kind)
      elsif predecessor.id != successor.id
        update_or_build_relationship(predecessor, successor, relationship_kind) # Direct Relationship
      end
    end

    #apply rules, update relationships and fetch matrix
    def build_relationship_matrix
      matrix = fetch_relationship_matrix
      apply_rules_and_update_relationships(matrix)
      fetch_relationship_matrix
    end

    def enrolled_with(enrollment)
      active_enrollments = enrollment.family.hbx_enrollments.enrolled_and_renewing

      enrollment.hbx_enrollment_members.each do |enrollment_member|
        family_member_id =  enrollment_member.applicant_id
        applicant = applicants.where(family_member_id: family_member_id).first
        next if ineligible_for_evidence_update?(enrollment, active_enrollments, family_member_id)

        applicant&.enrolled_with(enrollment)
      end
    end

    def ineligible_for_evidence_update?(enrollment, active_enrollments, family_member_id)
      return false if enrollment.health?
      family_member_enrollments = active_enrollments
                                  .by_year(enrollment.effective_on.year)
                                  .by_health
                                  .map { |en| en.hbx_enrollment_members.any? { |member| member.applicant_id == family_member_id } }

      family_member_enrollments.any?
    end

    # fetch existing relationships matrix
    def fetch_relationship_matrix
      applicant_ids = active_applicants.map(&:id)
      matrix_size = applicant_ids.count
      matrix = Array.new(matrix_size){Array.new(matrix_size)}
      id_map = {}
      applicant_ids.each_with_index { |hmid, index| id_map.merge!(index => hmid) }
      matrix.each_with_index do |x, xi|
        x.each_with_index do |_y, yi|
          matrix[xi][yi] = find_existing_relationship(id_map[xi], id_map[yi])
          matrix[yi][xi] = find_existing_relationship(id_map[yi], id_map[xi])
        end
      end
    end

    def find_existing_relationship(member_a_id, member_b_id)
      return 'self' if member_a_id == member_b_id

      rel = relationships.where(applicant_id: member_a_id, relative_id: member_b_id).first
      rel&.kind
    end

    def search_applicant(verified_family_member)
      ssn = verified_family_member.person_demographics.ssn
      ssn = '' if ssn == "999999999"
      dob = verified_family_member.person_demographics.birth_date
      last_name_regex = /^#{verified_family_member.person.name_last}$/i
      first_name_regex = /^#{verified_family_member.person.name_first}$/i

      if ssn.blank?
        applicants.where({
                           :dob => dob,
                           :last_name => last_name_regex,
                           :first_name => first_name_regex
                         }).first
      else
        applicants.where({
                           :encrypted_ssn => FinancialAssistance::Applicant.encrypt_ssn(ssn),
                           :dob => dob
                         }).first
      end
    end

    def find_all_relationships(matrix)
      id_map = {}
      applicant_ids = active_applicants.map(&:id)
      applicant_ids.each_with_index { |hmid, index| id_map.merge!(index => hmid) }
      invalid_ids = active_applicants.collect(&:invalid_family_relationships).flatten
      all_relationships = []
      matrix.each_with_index do |x, xi|
        x.each_with_index do |_y, yi|
          next unless xi < yi
          relation = relationships.where(applicant_id: id_map[xi], relative_id: id_map[yi]).first
          relation_kind = relation&.kind
          relation_has_error = invalid_ids.include?(relation&.id)
          all_relationships << {:applicant => id_map[xi], :relation => relation_kind, :relative => id_map[yi], :error => relation_has_error}
        end
      end
      all_relationships
    end

    def find_missing_relationships(matrix)
      return [] if matrix.flatten.all?(&:present?)
      id_map = {}
      applicant_ids = active_applicants.map(&:id)
      applicant_ids.each_with_index { |hmid, index| id_map.merge!(index => hmid) }
      missing_relationships = []
      matrix.each_with_index do |x, xi|
        x.each_with_index do |_y, yi|
          missing_relationships << {id_map[xi] => id_map[yi]} if (xi > yi) && matrix[xi][yi].blank?
        end
      end
      self.errors[:base] << I18n.t("faa.errors.missing_relationships")
      missing_relationships
    end

    def update_response_attributes(attrs)
      update_attributes(attrs)
    end

    def add_eligibility_determination(message)
      update_response_attributes(message)
      ed_updated = FinancialAssistance::Operations::Applications::Haven::AddEligibilityDetermination.new.call(application: self, eligibility_response_payload: eligibility_response_payload)
      return if ed_updated.failure? || ed_updated.value! == false
      determine! # If successfully loaded ed's move the application to determined state
    end

    def send_determination_to_ea
      return if EnrollRegistry.feature_enabled?(:temporary_configuration_enable_multi_tax_household_feature)

      result = ::Operations::Families::AddFinancialAssistanceEligibilityDetermination.new.call(self)
      if result.success?
        rt_transfer
        true
      else
        log(eligibility_response_payload, {:severity => 'critical', :error_message => "send_determination_to_ea ERROR: #{result.failure}"})
      end
    rescue StandardError => e
      log(eligibility_response_payload, { severity: 'critical',
                                          error_message: "send_determination_to_ea ERROR: #{e.message}, backtrace: #{e.backtrace.join('\n')}" })
      Rails.logger.error { "FAA send_determination_to_ea error for application with hbx_id: #{hbx_id} message: #{e.message}, backtrace: #{e.backtrace.join('\n')}" }
    end

    def rt_transfer
      return unless is_rt_transferrable?
      ::FinancialAssistance::Operations::Transfers::MedicaidGateway::AccountTransferOut.new.call(application_id: self.id)
    rescue StandardError => e
      Rails.logger.error { "FAA rt_transfer error for application with hbx_id: #{hbx_id} message: #{e.message}, backtrace: #{e.backtrace.join('\n')}" }
    end

    def transfer_account
      ::FinancialAssistance::Operations::Transfers::MedicaidGateway::AccountTransferOut.new.call(application_id: self.id)
    rescue StandardError => e
      Rails.logger.error { "FAA transfer_account error for application with hbx_id: #{hbx_id} message: #{e.message}, backtrace: #{e.backtrace.join('\n')}" }
    end

    def is_rt_transferrable?
      return unless FinancialAssistanceRegistry.feature_enabled?(:real_time_transfer) && self.account_transferred == false
      is_transferrable?
    end

    def is_batch_transferrable?
      return unless FinancialAssistanceRegistry.feature_enabled?(:batch_transfer)
      is_transferrable?
    end

    def is_transferrable?
      return false if FinancialAssistanceRegistry.feature_enabled?(:block_renewal_application_transfers) && previously_renewal_draft?
      return false unless active_applicants.any?(&:is_applying_coverage)
      unless FinancialAssistanceRegistry.feature_enabled?(:non_magi_transfer)
        # block transfer if any applicant is eligible for non-MAGI reasons
        return false if has_non_magi_referrals?
        return true if full_medicaid_determination
      end
      active_applicants.any? do |applicant|
        applicant.is_medicaid_chip_eligible || applicant.is_magi_medicaid || applicant.is_non_magi_medicaid_eligible || applicant.is_medicare_eligible || applicant.is_eligible_for_non_magi_reasons
      end
    end

    def has_non_magi_referrals?
      applicants.any? {|applicant| applicant.is_non_magi_medicaid_eligible || applicant.is_eligible_for_non_magi_reasons}
    end

    def has_mec_check?
      return unless FinancialAssistanceRegistry.feature_enabled?(:mec_check)
      self.has_mec_check_response
    end

    def update_application(error_message, status_code)
      set_determination_response_error!
      update_response_attributes(determination_http_status_code: status_code, has_eligibility_response: true, determination_error_message: error_message)
      log(eligibility_response_payload, {:severity => 'critical', :error_message => "ERROR: #{error_message}"})
    end

    def applicant_relative_exists_for_relations
      result = relationships.collect do |relationship|
        next if FinancialAssistance::Applicant.find(relationship.applicant_id).present? && FinancialAssistance::Applicant.find(relationship.relative_id).present?
        relationship
      end.compact
      if result.blank?
        true
      else
        self.errors[:base] << I18n.t("faa.errors.extra_relationship")
        false
      end
    end

    def validate_relationships(matrix)
      # validates the child has relationship as parent for 'spouse of the primary'.
      return false if applicants.collect(&:invalid_family_relationships).flatten.present?
      all_relationships = find_all_relationships(matrix)
      spouse_relation = all_relationships.select{|hash| hash[:relation] == "spouse"}.first
      return true unless spouse_relation.present?

      spouse_rel_id = spouse_relation.to_a.flatten.select{|a| a.is_a?(BSON::ObjectId) && a != primary_applicant.id}.first
      primary_parent_relations = relationships.where(applicant_id: primary_applicant.id, kind: 'parent')
      child_ids = primary_parent_relations.map(&:relative_id)
      spouse_parent_relations = relationships.where(:relative_id.in => child_ids.flatten, applicant_id: spouse_rel_id, kind: 'parent')

      if spouse_parent_relations.count == child_ids.flatten.count
        true
      else
        self.errors[:base] << I18n.t("faa.errors.invalid_household_relationships")
        false
      end
    end

    def apply_rules_and_update_relationships(matrix) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
      missing_relationships = find_missing_relationships(matrix)

      # Sibling rule
      # If MemberA and MemberB are children of MemberC, then both MemberA and MemberB are Siblings
      missing_relationships.each do |rel|
        first_rel = rel.to_a.flatten.first
        second_rel = rel.to_a.flatten.second
        relation1 = relationships.where(applicant_id: first_rel, kind: 'child').to_a
        relation2 = relationships.where(applicant_id: second_rel, kind: 'child').to_a

        relation = relation1 + relation2
        s_ids = relation.collect(&:relative_id)

        next unless s_ids.count > s_ids.uniq.count
        members = applicants.where(:id.in => rel.to_a.flatten)

        add_or_update_relationships(members.first, members.second, 'sibling')
        missing_relationships -= [rel] #Remove Updated Relation from list of missing relationships
      end

      # GrandParent/GrandChild
      # If MemberA is parent to MemberB and MemberB is parent to MemberC, then MemberA is GrandParent to MemberC
      # If MemberA is child to MemberB and MemberB is child to MemberC, then MemberA is GrandChild to MemberC

      # TODO: Need code refactor for all the rules
      # rubocop:disable Style/CombinableLoops
      missing_relationships.each do |rel|
        first_rel = rel.to_a.flatten.first
        second_rel = rel.to_a.flatten.second

        relation1 = relationships.where(applicant_id: first_rel, :kind.in => ['parent', 'child']).to_a
        relation2 = relationships.where(applicant_id: second_rel, :kind.in => ['parent', 'child']).to_a

        relation = relation1 + relation2
        s_ids = relation.collect(&:relative_id)

        s_ids.each do |p_id|
          parent_rel1 = relationships.where(relative_id: p_id, applicant_id: first_rel, kind: "parent").first
          child_rel1 = relationships.where(relative_id: p_id, applicant_id: first_rel, kind: "child").first
          parent_rel2 = relationships.where(relative_id: p_id, applicant_id: second_rel, kind: "parent").first
          child_rel2 = relationships.where(relative_id: p_id, applicant_id: second_rel, kind: "child").first

          if parent_rel1.present? && child_rel2.present?
            grandchild = applicants.where(id: second_rel).first
            grandparent = applicants.where(id: first_rel).first
            add_or_update_relationships(grandparent, grandchild, 'grandparent')
            missing_relationships -= [rel] #Remove Updated Relation from list of missing relationships
            break
          elsif child_rel1.present? && parent_rel2.present?
            grandchild = applicants.where(id: first_rel).first
            grandparent = applicants.where(id: second_rel).first
            add_or_update_relationships(grandparent, grandchild, 'grandparent')
            missing_relationships -= [rel] #Remove Updated Relation from list of missing relationships
            break
          end
        end
      end

      # Spouse Rule
      # When MemberA is child of MemberB, And MemberC is child to MemberD,
      # And MemberB, MemberD are spouse to eachother, Then MemberA, MemberC are Siblings
      missing_relationships.each do |rel|
        first_rel = rel.to_a.flatten.first
        second_rel = rel.to_a.flatten.second

        parent_rel1 = relationships.where(applicant_id: first_rel, kind: 'child').first
        parent_rel2 = relationships.where(applicant_id: second_rel, kind: 'child').first

        next unless parent_rel1.present? && parent_rel2.present?
        spouse_relation = relationships.where(applicant_id: parent_rel1.relative_id, relative_id: parent_rel2.relative_id, kind: "spouse").first
        next unless spouse_relation.present?
        members = applicants.where(:id.in => rel.to_a.flatten)
        add_or_update_relationships(members.first, members.second, 'sibling')
        missing_relationships -= [rel] #Remove Updated Relation from list of missing relationships
      end
      # rubocop:enable Style/CombinableLoops

      return matrix unless EnrollRegistry.feature_enabled?(:mitc_relationships)
      # FatherOrMotherInLaw/DaughterOrSonInLaw Rule: father_or_mother_in_law, daughter_or_son_in_law
      missing_relationships = execute_father_or_mother_in_law_rule(missing_relationships)

      # BrotherOrSisterInLaw Rule: brother_or_sister_in_law
      missing_relationships = execute_brother_or_sister_in_law_rule(missing_relationships)

      # Cousin Rule: cousin
      missing_relationships = execute_cousin_rule(missing_relationships)

      # DomesticPartnersChild Rule: domestic_partners_child
      missing_relationships = execute_domestic_partners_child_rule(missing_relationships)

      matrix
    end
    #TODO: end of work progress

    # Set the benchmark product for this financial assistance application.
    # @param benchmark_product_id [ {Plan} ] The benchmark product for this application.
    # def benchmark_product=(new_benchmark_product)
    #   raise ArgumentError.new("expected Product") unless new_benchmark_product.is_a?(BenefitMarkets::Products::Product)
    #   write_attribute(:benchmark_plan_id, new_benchmark_product._id)
    #   @benchmark_product = new_benchmark_product
    # end

    # Set the benchmark plan for this financial assistance application.
    # @param benchmark_plan_id [ {Plan} ] The benchmark plan for this application.
    # def benchmark_plan=(new_benchmark_plan)
    #   raise ArgumentError.new("expected Plan") unless new_benchmark_plan.is_a?(Plan)
    #   write_attribute(:benchmark_plan_id, new_benchmark_plan._id)
    #   @benchmark_plan = new_benchmark_plan
    # end

    # Get the benchmark product for this application.
    # @return [ {Product} ] benchmark product
    # def benchmark_product
    #   return @benchmark_product if defined? @benchmark_product
    #   @benchmark_product = BenefitMarkets::Products::Product.find(benchmark_product_id) unless benchmark_product_id.blank?
    # end

    # Virtual attribute that indicates whether Primary Applicant accepts the Medicaid terms
    # of service presented at the time of application submission
    # @return [ true, false ] true if application has reached workflow state of submitted (or later), false if not
    def has_accepted_medicaid_terms?
      SUBMITTED_STATUS.include?(aasm_state)
    end

    # Virtual attribute that indicates whether Primary Applicant accepts the Attest terms
    # of service presented at the time of application submission
    # @return [ true, false ] true if application has reached workflow state of submitted (or later), false if not
    def has_accepted_attestation_terms?
      SUBMITTED_STATUS.include?(aasm_state)
    end

    # Virtual attribute that indicates whether Primary Applicant accepts the Submit terms
    # of service presented at the time of application submission
    # @return [ true, false ] true if application has reached workflow state of submitted (or later), false if not
    def has_accepted_submission_terms?
      SUBMITTED_STATUS.include?(aasm_state)
    end

    # Get the {FamilyMember} who is primary for this application.
    # @return [ {FamilyMember} ] primary {FamilyMember}
    def primary_applicant
      @primary_applicant ||= applicants.detect(&:is_primary_applicant?)
    end

    def find_applicant(id)
      applicants.find(id)
    end


    # TODO: define the states and transitions for Assisted Application workflow process
    aasm do
      state :draft, initial: true
      # :renewal_draft State where the previous year's application is renewed
      # :renewal_draft state is the initial state for a renewal application
      state :renewal_draft
      # :income_verification_extension_required is a state where some corrective action is required
      # to extend income verification year.
      state :income_verification_extension_required
      state :submitted
      state :determination_response_error
      state :determined
      state :imported
      state :applicants_update_required
      # states when request build fails(to generate request for Haven/Mitc)
      state :mitc_magi_medicaid_eligibility_request_errored
      state :haven_magi_medicaid_eligibility_request_errored

      event :set_magi_medicaid_eligibility_request_errored, :after => :record_transition do
        if FinancialAssistanceRegistry.feature_enabled?(:haven_determination)
          transitions from: :submitted, to: :haven_magi_medicaid_eligibility_request_errored
        elsif FinancialAssistanceRegistry.feature_enabled?(:medicaid_gateway_determination)
          transitions from: :submitted, to: :mitc_magi_medicaid_eligibility_request_errored
        else
          raise NoMagiMedicaidEngine
        end
      end

      event :submit, :after => [:record_transition, :set_submit] do
        transitions from: [:draft,
                           :renewal_draft,
                           :haven_magi_medicaid_eligibility_request_errored,
                           :mitc_magi_medicaid_eligibility_request_errored], to: :submitted do
          guard do
            is_application_valid?
          end
        end

        transitions from: :draft, to: :draft, :after => :report_invalid do
          guard do
            !is_application_valid?
          end
        end

        transitions from: :renewal_draft, to: :renewal_draft, :after => :report_invalid do
          guard do
            !is_application_valid?
          end
        end
      end

      event :unsubmit, :after => [:record_transition, :unset_submit] do
        transitions from: :submitted, to: :renewal_draft do
          guard do
            previously_renewal_draft?
          end
        end

        transitions from: :submitted, to: :draft do
          guard do
            true # add appropriate guard here
          end
        end
      end

      event :set_determination_response_error, :after => :record_transition do
        transitions from: :submitted, to: :determination_response_error
      end

      event :determine, :after => [:record_transition, :create_tax_household_groups, :send_determination_to_ea, :create_evidences, :publish_application_determined, :notify_totally_ineligible_members] do
        transitions from: :submitted, to: :determined
      end

      event :determine_renewal, :after => [:record_transition, :create_tax_household_groups, :send_determination_to_ea, :create_evidences, :publish_application_determined] do
        transitions from: :submitted, to: :determined
      end

      event :terminate, :after => :record_transition do
        transitions from: [:submitted, :determined, :determination_response_error],
                    to: :terminated
      end

      event :cancel, :after => :record_transition do
        transitions from: [:draft],
                    to: :cancelled
      end

      # Currently, this event will be used during renewal generations
      event :set_income_verification_extension_required, :after => :record_transition do
        transitions from: :renewal_draft, to: :income_verification_extension_required
      end

      event :import, :after => [:record_transition] do
        transitions from: :draft, to: :imported
      end
    end

    # Evaluate if receiving Alternative Benefits this year
    def is_receiving_benefit?
      return_value = false

      alternate_benefits.each do |alternate_benefit|
        return_value = is_receiving_benefits_this_year?(alternate_benefit)
        break if return_value
      end

      return_value
    end

  ##### Methods below were transferred from EDI DB system
  ##### TODO: verify utility and improve names

    def compute_yearwise(incomes_or_deductions) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity TODO: Remove this
      income_deduction_per_year = Hash.new(0)

      incomes_or_deductions.each do |income_deduction|
        working_days_in_year = Float(52 * 5)
        daily_income = 0

        case income_deduction.frequency
        when "daily"
          daily_income = income_deduction.amount_in_cents
        when "weekly"
          daily_income = income_deduction.amount_in_cents / (working_days_in_year / 52)
        when "biweekly"
          daily_income = income_deduction.amount_in_cents / (working_days_in_year / 26)
        when "monthly"
          daily_income = income_deduction.amount_in_cents / (working_days_in_year / 12)
        when "quarterly"
          daily_income = income_deduction.amount_in_cents / (working_days_in_year / 4)
        when "half_yearly"
          daily_income = income_deduction.amount_in_cents / (working_days_in_year / 2)
        when "yearly"
          daily_income = income_deduction.amount_in_cents / working_days_in_year
        end

        income_deduction.start_date = TimeKeeper.date_of_record.beginning_of_year if income_deduction.start_date.to_s.eql?("01-01-0001" || income_deduction.start_date.blank?)
        income_deduction.end_date   = TimeKeeper.date_of_record.end_of_year if income_deduction.end_date.to_s.eql?("01-01-0001" || income_deduction.end_date.blank?)
        years = (income_deduction.start_date.year..income_deduction.end_date.year)

        years.to_a.each do |year|
          actual_days_worked = compute_actual_days_worked(year, income_deduction.start_date, income_deduction.end_date)
          income_deduction_per_year[year] += actual_days_worked * daily_income
        end
      end

      income_deduction_per_year.merge(income_deduction_per_year) do |_k, v|

        Integer(v)
      rescue StandardError
        v

      end
    end

    # Compute the actual days a applicant worked during one year
    def compute_actual_days_worked(year, start_date, end_date)
      working_days_in_year = Float(52 * 5)

      start_date_to_consider = if Date.new(year, 1, 1) < start_date
                                 start_date
                               else
                                 Date.new(year, 1, 1)
                               end

      end_date_to_consider = if Date.new(year, 1, 1).end_of_year < end_date
                               Date.new(year, 1, 1).end_of_year
                             else
                               end_date
                             end

      # we have to add one to include last day of work. We multiply by working_days_in_year/365 to remove weekends.
      ((end_date_to_consider - start_date_to_consider + 1).to_i * (working_days_in_year / 365)).to_i #actual days worked in 'year'
    end

    def is_receiving_benefits_this_year?(alternate_benefit)
      alternate_benefit.start_date = TimeKeeper.date_of_record.beginning_of_year if alternate_benefit.start_date.blank?
      alternate_benefit.end_date =   TimeKeeper.date_of_record.end_of_year if alternate_benefit.end_date.blank?
      (alternate_benefit.start_date.year..alternate_benefit.end_date.year).include? TimeKeeper.date_of_record.year
    end

    def publish_esi_mec_request
      return unless FinancialAssistanceRegistry.feature_enabled?(:esi_mec_determination)

      Operations::Applications::Esi::H14::EsiMecRequest.new.call(application_id: id)
    end

    def publish_non_esi_mec_request
      return unless FinancialAssistanceRegistry.feature_enabled?(:non_esi_mec_determination)

      Operations::Applications::NonEsi::H31::NonEsiMecRequest.new.call(application_id: id)
    end

    def update_evidence_histories
      assistance_evidences = %w[esi_evidence non_esi_evidence local_mec_evidence income_evidence]

      active_applicants.each do |applicant|
        applicant.update_evidence_histories(assistance_evidences)
      end
    rescue StandardError => e
      Rails.logger.error { "FAA update_evidence_histories error for application with hbx_id: #{hbx_id} message: #{e.message}, backtrace: #{e.backtrace.join('\n')}" }
    end

    def can_trigger_fdsh_calls?
      FinancialAssistanceRegistry.feature_enabled?(:esi_mec_determination) ||
        FinancialAssistanceRegistry.feature_enabled?(:non_esi_mec_determination) ||
        FinancialAssistanceRegistry.feature_enabled?(:ifsv_determination)
    end

    def publish_application_determined
      return unless can_trigger_fdsh_calls? || is_local_mec_checkable?
      return if previously_renewal_draft? && FinancialAssistanceRegistry.feature_enabled?(:renewal_eligibility_verification_using_rrv)

      ::FinancialAssistance::Operations::Applications::Verifications::RequestEvidenceDetermination.new.call(self)
    rescue StandardError => e
      Rails.logger.error { "FAA trigger_fdsh_calls error for application with hbx_id: #{hbx_id} message: #{e.message}, backtrace: #{e.backtrace.join('\n')}" }
    end

    def notify_totally_ineligible_members
      return unless any_applicants_totally_ineligible? && FinancialAssistanceRegistry.feature_enabled?(:totally_ineligible_notice)

      ::FinancialAssistance::Operations::Applications::Verifications::PublishFaaTotalIneligibilityNotice.new.call(self)
    rescue StandardError => e
      Rails.logger.error { "FAA faa_totally_ineligible_notice error for application with hbx_id: #{hbx_id} message: #{e.message}, backtrace: #{e.backtrace.join('\n')}" }
    end

    def apply_aggregate_to_enrollment
      return unless EnrollRegistry.feature_enabled?(:apply_aggregate_to_enrollment) || !previously_renewal_draft?
      return if retro_application
      on_new_determination = ::Operations::Individual::OnNewDetermination.new.call({family: self.family, year: self.effective_date.year})
      if on_new_determination.success?
        Rails.logger.info { "Successfully created new enrollment on_new_determination: #{self.hbx_id}" }
        true
      else
        Rails.logger.error { "Failed while creating enrollment on_new_determination: #{self.hbx_id}, Failure Message: #{on_new_determination.failure}" }
        false
      end
    rescue StandardError => e
      Rails.logger.error("Error while creating enrollment on_new_determination: #{self.hbx_id}, Error: #{e.message}")
      false
    end

    def retro_application
      self.effective_date.year < TimeKeeper.date_of_record.year
    end

    def create_tax_household_groups
      return unless EnrollRegistry.feature_enabled?(:temporary_configuration_enable_multi_tax_household_feature)

      determination = family.create_thhg_on_fa_determination(self)

      unless determination.success?
        Rails.logger.error { "Failed while creating group fa determination: #{self.hbx_id}, Error: #{determination.failure}" }
        return
      end

      rt_transfer

      family_determination = ::Operations::Eligibilities::BuildFamilyDetermination.new.call(family: self.family.reload, effective_date: self.effective_date.to_date)

      if family_determination.success?
        apply_aggregate_to_enrollment
      else
        Rails.logger.error { "Failed while creating family determination: #{self.hbx_id}, Error: #{family_determination.failure}" }
      end
    rescue StandardError => e
      Rails.logger.error { "FAA create_tax_household_groups error for application with hbx_id: #{hbx_id} message: #{e.message}, backtrace: #{e.backtrace.join('\n')}" }
    end

    def trigger_local_mec
      ::FinancialAssistance::Operations::Applications::MedicaidGateway::RequestMecChecks.new.call(application_id: id) if is_local_mec_checkable?
    rescue StandardError => e
      Rails.logger.error { "FAA trigger_local_mec error for application with hbx_id: #{hbx_id} message: #{e.message}, backtrace: #{e.backtrace.join('\n')}" }
    end

    def is_local_mec_checkable?
      return unless FinancialAssistanceRegistry.feature_enabled?(:mec_check)
      self.active_applicants.any?(&:is_ia_eligible?)
    end

    def total_incomes_by_year
      incomes_by_year = compute_yearwise(incomes)
      deductions_by_year = compute_yearwise(deductions)

      years = incomes_by_year.keys | deductions_by_year.keys

      total_incomes = {}

      years.each do |y|
        income_this_year = incomes_by_year[y] || 0
        deductions_this_year = deductions_by_year[y] || 0
        total_incomes[y] = (income_this_year - deductions_this_year) * 0.01
      end
      total_incomes
    end

    def is_family_totally_ineligibile
      active_applicants.each { |applicant| return false unless applicant.is_totally_ineligible }
      true
    end

    def active_determined_eligibility_determinations
      eligibility_determinations.where(is_eligibility_determined: true)
    end

    def current_csr_percent_as_integer(eligibility_determination_id)
      eligibility_determination = eligibility_determination_for(eligibility_determination_id)
      eligibility_determination.present? ? eligibility_determination.csr_percent_as_integer : 0
    end

    def eligibility_determination_for(eligibility_determination_id)
      eligibility_determinations.where(id: eligibility_determination_id).first
    end

    def eligibility_determination_for_family_member(family_member_id)
      eligibility_determinations.where(is_eligibility_determined: true).select {|th| th if th.active_applicants.where(family_member_id: family_member_id).present? }.first
    end

    def latest_active_eligibility_determinations_with_year(year)
      eligibility_determinations = active_determined_eligibility_determinations.eligibility_determination_with_year(year)
      eligibility_determinations = active_determined_eligibility_determinations.eligibility_determination_with_year(year).active_eligibility_determination if TimeKeeper.date_of_record.year == year
      eligibility_determinations
    end

    def eligibility_determinations_for_year(year)
      return nil unless self.assistance_year == year
      self.eligibility_determinations
    end

    def complete?
      is_application_valid? # && check for the validity of applicants too.
    end

    def is_submitted?
      self.aasm_state == "submitted"
    end

    def send_failed_response
      return unless FinancialAssistanceRegistry.feature_enabled?(:haven_determination)
      primary_applicant_person_hbx_id = primary_applicant.person_hbx_id
      unless has_eligibility_response
        if determination_http_status_code == 999
          log("Timed Out: Eligibility Response Error", {:severity => 'critical', :error_message => "999 Eligibility Response Error for application_id #{hbx_id}, primary_applicant_person_hbx_id: #{primary_applicant_person_hbx_id}"})
        end
        message = "Timed-out waiting for eligibility determination response"
        return_status = 504
        notify("acapi.info.events.eligibility_determination.rejected",
               {:correlation_id => SecureRandom.uuid.gsub("-",""),
                :body => { error_message: message },
                :family_id => family_id.to_s,
                :assistance_application_id => hbx_id.to_s,
                primary_applicant_person_hbx_id: primary_applicant_person_hbx_id,
                :return_status => return_status.to_s,
                :submitted_timestamp => TimeKeeper.date_of_record.strftime('%Y-%m-%dT%H:%M:%S')})
      end

      return unless has_eligibility_response && determination_http_status_code == 422 && determination_error_message == "Failed to validate Eligibility Determination response XML"
      message = "Invalid schema eligibility determination response provided"
      log(message, {:severity => 'critical', :error_message => "422 Eligibility Response Error for application_id #{hbx_id}, primary_applicant_person_hbx_id: #{primary_applicant_person_hbx_id}"})
      notify("acapi.info.events.eligibility_determination.rejected",
             {:correlation_id => SecureRandom.uuid.gsub("-",""),
              :body => { error_message: message },
              :family_id => family_id.to_s,
              :assistance_application_id => hbx_id.to_s,
              primary_applicant_person_hbx_id: primary_applicant_person_hbx_id,
              :return_status => determination_http_status_code.to_s,
              :submitted_timestamp => TimeKeeper.date_of_record.strftime('%Y-%m-%dT%H:%M:%S'),
              :haven_application_id => haven_app_id,
              :haven_ic_id => haven_ic_id })
    end

    def ready_for_attestation?
      application_valid = is_application_ready_for_attestation?
      # && chec.k for the validity of all applicants too.
      self.active_applicants.each do |applicant|
        return false unless applicant.applicant_validation_complete?
      end
      application_valid && relationships_complete?
    end

    def relationships_complete?
      matrix = build_relationship_matrix
      is_valid = [find_missing_relationships(matrix).blank?]
      is_valid << applicant_relative_exists_for_relations
      is_valid.all?(true)
    end

    def valid_relationship_kinds?
      relationships.all?(&:valid_relationship_kind?)
    end

    def valid_relations?
      matrix = build_relationship_matrix
      EnrollRegistry.feature_enabled?(:mitc_relationships) ? validate_relationships(matrix) : true
    end

    def is_draft?
      self.aasm_state == "draft"
    end

    def is_determined?
      self.aasm_state == "determined"
    end

    def is_terminated?
      self.aasm_state == "terminated"
    end

    def is_reviewable?
      REVIEWABLE_STATUSES.include?(aasm_state)
    end

    def is_closed?
      CLOSED_STATUSES.include?(aasm_state)
    end

    def incomplete_applicants?
      active_applicants.each do |applicant|
        return true unless applicant.applicant_validation_complete?
      end
      false
    end

    def next_incomplete_applicant
      active_applicants.each do |applicant|
        return applicant if applicant.applicant_validation_complete? == false
      end
    end

    def eligible_for_renewal?
      return true unless FinancialAssistanceRegistry.feature_enabled?(:skip_eligibility_redetermination)
      return true if has_eligible_applicants_for_assistance?
      return false if all_applicants_medicaid_or_chip_eligible?
      return false if all_applicants_totally_ineligible?
      return false if all_applicants_without_applying_for_coverage?

      true
    end

    def has_eligible_applicants_for_assistance?
      active_applicants.any? { |applicant| applicant.is_without_assistance || applicant.is_ia_eligible }
    end

    def all_applicants_medicaid_or_chip_eligible?
      active_applicants.all?(&:is_medicaid_chip_eligible)
    end

    def all_applicants_totally_ineligible?
      active_applicants.all?(&:is_totally_ineligible)
    end

    def any_applicants_totally_ineligible?
      active_applicants.any?(&:is_totally_ineligible)
    end

    def all_applicants_without_applying_for_coverage?
      active_applicants.all? { |applicant| !applicant.is_applying_coverage }
    end

    def active_applicants
      applicants.where(:is_active => true)
    end

    def calculate_total_net_income_for_applicants
      active_applicants.each do |applicant|
        FinancialAssistance::Operations::Applicant::CalculateAndPersistNetAnnualIncome.new.call({application_assistance_year: assistance_year, applicant: applicant})
      end
    end

    def non_primary_applicants
      active_applicants.reject{|applicant| applicant == primary_applicant}
    end

    def clean_conditional_params(model_params)
      clean_params(model_params)
    end

    def success_status_codes?(payload_http_status_code)
      [200, 203].include?(payload_http_status_code)
    end

    def check_verification_response # rubocop:disable Metrics/CyclomaticComplexity
      return unless !has_all_uqhp_applicants? && !has_atleast_one_medicaid_applicant? && !has_all_verified_applicants? && (TimeKeeper.datetime_of_record.prev_day > submitted_at)
      return unless timeout_response_last_submitted_at.blank? || (timeout_response_last_submitted_at.present? && (TimeKeeper.datetime_of_record.prev_day > timeout_response_last_submitted_at))
      self.update_attributes(timeout_response_last_submitted_at: TimeKeeper.datetime_of_record)
      active_applicants.each do |applicant|
        if !applicant.has_income_verification_response && !applicant.has_mec_verification_response
          type = "Income, MEC"
        elsif applicant.has_income_verification_response && !applicant.has_mec_verification_response
          type = "MEC"
        elsif !applicant.has_income_verification_response && applicant.has_mec_verification_response
          type = "Income"
        end
        notify("acapi.info.events.verification.rejected",
               { :correlation_id => SecureRandom.uuid.gsub("-",""),
                 :body => JSON.dump({
                                      error: "Timed-out waiting for verification response",
                                      applicant_first_name: applicant.first_name,
                                      applicant_last_name: applicant.last_name,
                                      applicant_id: applicant.person_hbx_id,
                                      rejected_verification_types: type
                                    }),
                 :assistance_application_id => self._id.to_s,
                 :family_id => self.family_id.to_s,
                 :haven_application_id => haven_app_id,
                 :haven_ic_id => haven_ic_id,
                 :reject_status => 504,
                 :submitted_timestamp => TimeKeeper.datetime_of_record.strftime('%Y-%m-%dT%H:%M:%S')})
      end
    end

    def has_all_verified_applicants?
      !active_applicants.map(&:has_income_verification_response).include?(false) && !active_applicants.map(&:has_mec_verification_response).include?(false)
    end

    def has_atleast_one_medicaid_applicant?
      active_applicants.map(&:is_medicaid_chip_eligible).include?(true)
    end

    def has_all_uqhp_applicants?
      !active_applicants.map(&:is_without_assistance).include?(false)
    end

    def has_atleast_one_assisted_but_no_medicaid_applicant?
      active_applicants.map(&:is_ia_eligible).include?(true) && !active_applicants.map(&:is_medicaid_chip_eligible).include?(true)
    end

    class << self
      def advance_day(new_date)
        adv_day_logger = Logger.new("#{Rails.root}/log/fa_application_advance_day_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
        ope_result = FinancialAssistance::Operations::Applications::ProcessDateChangeEvents.new.call(
          { events_execution_date: new_date, logger: adv_day_logger, renewal_year: TimeKeeper.date_of_record.year.next }
        )
        adv_day_logger.info ope_result.success
      end
    end

    def attesations_complete?
      !is_requesting_voter_registration_application_in_mail.nil? &&
        (is_renewal_authorized.present? || (is_renewal_authorized.is_a?(FalseClass) && years_to_renew.present?)) &&
        !medicaid_terms.nil? &&
        !report_change_terms.nil? &&
        !medicaid_insurance_collection_terms.nil? &&
        check_parent_living_out_of_home_terms &&
        !submission_terms.nil?
    end

    def have_permission_to_renew?
      renewal_base_year >= assistance_year if assistance_year && renewal_base_year
    end

    def previously_renewal_draft?
      workflow_state_transitions.any? { |wst| wst.from_state == 'renewal_draft' }
    end

    def set_renewal_base_year
      return if renewal_base_year.present?
      renewal_year = calculate_renewal_base_year
      update_attribute(:renewal_base_year, renewal_year) if renewal_year.present?
    end

    def calculate_renewal_base_year
      ass_year = assistance_year.present? ? assistance_year : TimeKeeper.date_of_record.year
      if is_renewal_authorized.present?
        ass_year + YEARS_TO_RENEW_RANGE.max
      elsif is_renewal_authorized.is_a?(FalseClass)
        ass_year + (years_to_renew || 0)
      end
    end

    # Case1: Missing address - No address objects at all
    # Case2: Primary applicant should have a valid address
    def applicants_have_valid_addresses?
      addresses_valid = applicants.all?{|applicant| applicant.addresses.where(:kind.in => ['home', 'mailing']).present?} && primary_applicant.has_valid_address?
      self.errors[:base] << 'You must have a valid addresses for every applicant.' unless addresses_valid
      addresses_valid
    end

    def required_attributes_valid?
      return true if renewal_draft?

      self.valid?(:submission)
    end

    def is_application_valid?
      required_attributes_valid? && relationships_complete? && applicants_have_valid_addresses?
    end

    # Used for performance improvement cacheing.
    attr_writer :family

    # rubocop:disable Lint/EmptyRescueClause
    def family
      @family ||= begin
        Family.find(family_id)
      rescue StandardError => _e
        nil
      end
    end
    # rubocop:enable Lint/EmptyRescueClause

    def set_assistance_year
      return unless assistance_year.blank?
      update_attribute(:assistance_year,
                       FinancialAssistanceRegistry[:enrollment_dates].settings(:application_year).item.constantize.new.call.value!)
    end

    def create_rrv_evidences
      active_applicants.each do |applicant|
        applicant.create_evidence(:non_esi_mec, "Non ESI MEC")
        applicant.create_eligibility_income_evidence if active_applicants.any?(&:is_ia_eligible?) || active_applicants.any?(&:is_applying_coverage)
        applicant.save!
      end
    end

    def create_rrv_evidence_histories
      rrv_evidences = %w[non_esi_evidence income_evidence]

      active_applicants.each do |applicant|
        applicant.create_rrv_evidence_histories(rrv_evidences)
      end
    end

    def build_new_relationship(applicant, rel_kind, relative)
      rel_params = { applicant_id: applicant&.id, kind: rel_kind, relative_id: relative&.id }
      return if rel_params.values.include?(nil) || applicant&.id == relative&.id

      relationship = relationships.where({ applicant_id: applicant&.id, relative_id: relative&.id }).first
      if relationship.present?
        relationship.kind = rel_kind
      elsif relationships.where(rel_params).blank?
        relationships.build(rel_params)
      end
    end

    def build_new_applicant(applicant_params)
      applicants.build(applicant_params)
    end

    def aptc_applicants
      applicants.aptc_eligible
    end

    def medicaid_or_chip_applicants
      applicants.medicaid_or_chip_eligible
    end

    # UQHP, is_without_assistance
    def uqhp_applicants
      applicants.uqhp_eligible
    end

    def ineligible_applicants
      applicants.ineligible
    end

    # is_eligible_for_non_magi_reasons, is_non_magi_medicaid_eligible
    def applicants_with_non_magi_reasons
      applicants.eligible_for_non_magi_reasons
    end

    def applicants_applying_coverage
      applicants.applying_coverage
    end

    def dependents
      active_applicants.where(is_primary_applicant: false)
    end

    def update_dependents_home_address
      address_keys = ["address_1", "address_2", "address_3", "city", "state", "zip", "kind"]
      address_keys << "county" if EnrollRegistry.feature_enabled?(:display_county)
      primary_applicant = applicants.where(is_primary_applicant: true).first
      home_address_attributes = primary_applicant.home_address.attributes.slice(*address_keys)
      no_state_address_attributes = primary_applicant.attributes.slice("is_homeless", "is_temporarily_out_of_state")

      dependents.where(same_with_primary: true).each do |dependent|
        if dependent.home_address
          dependent.home_address.assign_attributes(home_address_attributes)
        else
          address = ::FinancialAssistance::Locations::Address.new(home_address_attributes)
          dependent.addresses << address
        end
        dependent.assign_attributes(no_state_address_attributes)
        dependent.save!
      end
    end

    private

    # If MemberA is parent to MemberB,
    # and MemberB is Spouse to MemberC,
    # then MemberA is father_or_mother_in_law to MemberC
    def execute_father_or_mother_in_law_rule(missing_relationships)
      missing_relationships.each do |rel|
        applicant_ids = rel.to_a.flatten
        applicant_relations = relationships.where(:applicant_id.in => applicant_ids, kind: 'parent')
        applicant_relations.each do |each_relation|
          other_applicant_id = (applicant_ids - [each_relation.applicant_id]).first
          spouse_relation = relationships.where(applicant_id: other_applicant_id, kind: 'spouse').first
          next if spouse_relation.nil? || spouse_relation.relative_id != each_relation.relative_id
          parent_in_law = applicants.where(id: each_relation.applicant_id).first
          child_in_law = applicants.where(id: other_applicant_id).first
          add_or_update_relationships(parent_in_law, child_in_law, 'father_or_mother_in_law')
          missing_relationships -= [rel] #Remove Updated Relation from list of missing relationships
        end
      end
      missing_relationships
    end

    # If MemberA is spouse to MemberB,
    # and MemberB is sibling to MemberC,
    # then MemberA is brother_or_sister_in_law to MemberC
    def execute_brother_or_sister_in_law_rule(missing_relationships)
      missing_relationships.each do |rel|
        applicant_ids = rel.to_a.flatten
        applicant_relations = relationships.where(:applicant_id.in => applicant_ids, kind: 'spouse')
        applicant_relations.each do |each_relation|
          # Do not continue if there are no missing relationships.
          return missing_relationships if missing_relationships.blank?
          other_applicant_id = (applicant_ids - [each_relation.applicant_id]).first
          sibling_relation = relationships.where(applicant_id: other_applicant_id, kind: 'sibling').first
          next if sibling_relation.nil? || sibling_relation.relative_id != each_relation.relative_id
          sibling1_in_law = applicants.where(id: each_relation.applicant_id).first
          sibling2_in_law = applicants.where(id: other_applicant_id).first
          add_or_update_relationships(sibling1_in_law, sibling2_in_law, 'brother_or_sister_in_law')
          missing_relationships -= [rel] #Remove Updated Relation from list of missing relationships
        end
      end
      missing_relationships
    end

    # If MemberA is nephew_or_niece to MemberB,
    # and MemberB is parent to MemberC,
    # then MemberA is cousin to MemberC
    def execute_cousin_rule(missing_relationships)
      missing_relationships.each do |rel|
        applicant_ids = rel.to_a.flatten
        applicant_relations = relationships.where(:applicant_id.in => applicant_ids, kind: 'nephew_or_niece')
        applicant_relations.each do |each_relation|
          # Do not continue if there are no missing relationships.
          return missing_relationships if missing_relationships.blank?
          other_applicant_id = (applicant_ids - [each_relation.applicant_id]).first
          child_relation = relationships.where(applicant_id: other_applicant_id, kind: 'child').first
          next if child_relation.nil? || child_relation.relative_id != each_relation.relative_id
          cousin1 = applicants.where(id: each_relation.applicant_id).first
          cousin2 = applicants.where(id: other_applicant_id).first
          add_or_update_relationships(cousin1, cousin2, 'cousin')
          missing_relationships -= [rel] #Remove Updated Relation from list of missing relationships
        end
      end
      missing_relationships
    end

    # If MemberA is domestic_partner to MemberB,
    # and MemberB is parent to MemberC,
    # then MemberA is parents_domestic_partner to MemberC
    def execute_domestic_partners_child_rule(missing_relationships)
      missing_relationships.each do |rel|
        applicant_ids = rel.to_a.flatten
        applicant_relations = relationships.where(:applicant_id.in => applicant_ids, kind: 'domestic_partner')
        applicant_relations.each do |each_relation|
          # Do not continue if there are no missing relationships.
          return missing_relationships if missing_relationships.blank?
          other_applicant_id = (applicant_ids - [each_relation.applicant_id]).first
          child_relation = relationships.where(applicant_id: other_applicant_id, kind: 'child').first
          next if child_relation.nil? || child_relation.relative_id != each_relation.relative_id
          parents_domestic_partner = applicants.where(id: each_relation.applicant_id).first
          domestic_partners_child = applicants.where(id: other_applicant_id).first
          # pivotal ticket: 180576660 domestic_partner should be able to select parent for primary's child_dependent or vice versa
          #  MemberA is domestic_partner to MemberB
          #  MemberA is parent to MemberC
          #  MemberB should be able to select MemberC as parent
          # add_or_update_relationships(parents_domestic_partner, domestic_partners_child, 'parents_domestic_partner')
          missing_relationships -= [rel] #Remove Updated Relation from list of missing relationships
        end
      end
      missing_relationships
    end

    def check_parent_living_out_of_home_terms
      (parent_living_out_of_home_terms.present? && !attestation_terms.nil?) ||
        parent_living_out_of_home_terms.is_a?(FalseClass)
    end

    def clean_params(model_params)
      model_params[:attestation_terms] = nil if model_params[:parent_living_out_of_home_terms].present? && model_params[:parent_living_out_of_home_terms] == 'false'
      model_params[:years_to_renew] = "5" if model_params[:is_renewal_authorized].present? && model_params[:is_renewal_authorized] == "true"
    end

    def attestation_terms_on_parent_living_out_of_home
      return unless parent_living_out_of_home_terms
      errors.add(:attestation_terms, "can't be blank") if attestation_terms.nil?
    end

    def trigger_eligibilility_notice
      if is_family_totally_ineligibile
        IvlNoticesNotifierJob.perform_later(self.primary_applicant.id.to_s, "ineligibility_notice")
      else
        IvlNoticesNotifierJob.perform_later(self.primary_applicant.id.to_s, "eligibility_notice")
      end
    end

    def set_hbx_id
      #TODO: Use hbx_id generator for Application
      write_attribute(:hbx_id, FinancialAssistance::HbxIdGenerator.generate_application_id) if hbx_id.blank?
    end

    def set_applicant_kind
      #TODO: Implement logic to handle "call center rep or case worker", "authorized representative"
      write_attribute(:applicant_kind, "user and/or family")
    end

    def set_request_kind
      #TODO: Populate correct request kind
      write_attribute(:request_kind, "placeholder")
    end

    def set_motivation_kind
      #TODO: Populate correct motivation kind
      write_attribute(:motivation_kind, "insurance_affordability")
    end

    def set_is_ridp_verified
      #TODO: Rewrite to populate RIDP result?
      write_attribute(:is_ridp_verified, true)
    end

    # TODO: Check if we have to fall back to FinancialAssistanceRegistry.
    def set_us_state
      write_attribute(
        :us_state,
        FinancialAssistanceRegistry[:enroll_app].setting(:state_abbreviation).item
      )
    end

    def set_submission_date
      update_attribute(:submitted_at, Time.current)
    end

    def set_effective_date
      return if effective_date.present?
      effective_date = SAFE_REGISTRY_METHODS.fetch(FinancialAssistanceRegistry[:enrollment_dates].settings(:earliest_effective_date).item).new.call(assistance_year: assistance_year).value!
      update_attribute(:effective_date, effective_date)
    end

    # def set_benchmark_product_id
    #   benchmark_product_id = HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period.slcsp
    #   write_attribute(:benchmark_product_id, benchmark_product_id)
    # end

    def active_approved_application
      return unless family_id.present?
      self.class.where(
        aasm_state: "determined",
        family_id: family_id,
        assistance_year: FinancialAssistanceRegistry[:enrollment_dates].settings(:application_year).item.constantize.new.call.value!
      ).order_by(:submitted_at => 'desc').first
    end

    def set_external_identifiers
      app = active_approved_application
      return unless app.present?
      write_attribute(:haven_app_id, app.haven_app_id)
      write_attribute(:haven_ic_id, app.haven_ic_id)
      write_attribute(:e_case_id, app.e_case_id)
    end

    def unset_submission_date
      update_attribute(:submitted_at, nil)
    end

    def unset_assistance_year
      update_attribute(:assistance_year, nil)
    end

    def unset_effective_date
      update_attribute(:effective_date, nil)
    end

    def application_submission_validity
      # Mandatory Fields before submission
      required_attributes_valid = validates_presence_of :hbx_id, :applicant_kind, :request_kind, :motivation_kind, :us_state

      required_boolean_attributes_valid = validates_inclusion_of :is_ridp_verified, :parent_living_out_of_home_terms, in: [true, false]
      # User must agree with terms of service check boxes before submission
      terms_attributes_valid = validates_acceptance_of :medicaid_terms, :submission_terms, :medicaid_insurance_collection_terms, :report_change_terms, accept: true

      required_attributes_valid && required_boolean_attributes_valid && terms_attributes_valid
    end

    def before_attestation_validity
      validates_presence_of :hbx_id, :applicant_kind, :request_kind, :motivation_kind, :us_state, :is_ridp_verified
    end

    def is_application_ready_for_attestation?
      self.valid?(:before_attestation) ? true : false
    end

    def report_invalid
      #TODO: Invalid Report here
    end

    # Example: application.determine will change the aasm_state in-memory, data is not persisted at this point.
    # When trying to find latest determine application in subsequent after call methods, previous application is fetched instead of current application.
    # Persisting the application right after the aasm_state change will avoid issues reated the fetching the latest application.
    def record_transition
      self.save if self.aasm_state_changed?
      self.workflow_state_transitions << WorkflowStateTransition.new(
        from_state: aasm.from_state,
        to_state: aasm.to_state
      )
    end

    def verification_update_for_applicants
      return unless aasm_state == "determined" || is_closed?
      if has_atleast_one_medicaid_applicant?
        update_verifications_of_applicants("external_source")
      elsif has_all_uqhp_applicants?
        update_verifications_of_applicants("not_required")
      elsif has_atleast_one_assisted_but_no_medicaid_applicant?
        update_verifications_of_applicants("pending")
      end
    end

    def set_submit
      return unless submitted?
      calculate_total_net_income_for_applicants
      set_submission_date
      set_assistance_year
      set_effective_date
      create_eligibility_determinations
      set_renewal_base_year
    end

    def trigger_fdsh_hub_calls
      publish_esi_mec_request
      publish_non_esi_mec_request
    end

    def unset_submit
      unset_submission_date
      unset_assistance_year
      unset_effective_date
      delete_eligibility_determinations
    end

    def create_eligibility_determinations
      ## Remove  when copy method is fixed to exclude copying Tax Household
      active_applicants.update_all(eligibility_determination_id: nil)

      non_tax_dependents = active_applicants.where(is_claimed_as_tax_dependent: false)
      tax_dependents = active_applicants.where(is_claimed_as_tax_dependent: true)

      non_tax_dependents.each do |applicant|
        if applicant.is_joint_tax_filing? && applicant.is_not_in_a_tax_household? && applicant.eligibility_determination_of_spouse.present?
          applicant.eligibility_determination = applicant.eligibility_determination_of_spouse
          applicant.update_attributes(tax_filer_kind: 'tax_filer')
        else
          # Create a new THH and assign it to the applicant
          # Need THH for Medicaid cases too
          applicant.eligibility_determination = eligibility_determinations.create!
          applicant.update_attributes(tax_filer_kind: applicant.tax_filing? ? 'tax_filer' : 'non_filer')
        end
      end

      tax_dependents.each do |applicant|
        thh_of_claimer = non_tax_dependents.find(applicant.claimed_as_tax_dependent_by).eligibility_determination
        applicant.eligibility_determination = thh_of_claimer if thh_of_claimer.present?
        applicant.update_attributes(tax_filer_kind: 'dependent')
      end

      empty_ed = eligibility_determinations.select do |ed|
        active_applicants.map(&:eligibility_determination).exclude?(ed)
      end
      empty_ed.each(&:destroy)
    end

    def delete_eligibility_determinations
      eligibility_determinations.destroy_all
    end

    def create_evidences
      return if previously_renewal_draft? && FinancialAssistanceRegistry.feature_enabled?(:renewal_eligibility_verification_using_rrv)

      active_applicants.each do |applicant|
        applicant.create_evidences
        applicant.create_eligibility_income_evidence if active_applicants.any?(&:is_ia_eligible?) || active_applicants.any?(&:is_applying_coverage)
      end
    rescue StandardError => e
      Rails.logger.error { "FAA create_evidences error for application with hbx_id: #{hbx_id} message: #{e.message}, backtrace: #{e.backtrace.join('\n')}" }
    end

    def create_income_verification(applicant)
      return unless family.present? && applicant.incomes.blank? && applicant.family_member_id.present?

      family_member_record = family.family_members.where(id: applicant.family_member_id).first
      return unless family_member_record.present?

      person_record = family_member_record.person
      return unless person_record.present?

      person_record.add_new_verification_type('Income')

      from_state = applicant.aasm_state
      # TODO: revisit
      applicant.write_attribute(:aasm_state, 'verification_pending')
      applicant.workflow_state_transitions << WorkflowStateTransition.new(
        from_state: from_state,
        to_state: 'verification_pending',
        event: 'move_to_pending!'
      )
    end

    def delete_verification_documents
      active_applicants.each do |applicant|
        applicant.verification_types.destroy_all
        applicant.move_to_unverified!
      end
    end
  end
end
