# frozen_string_literal: true

# dummy spec for hbx_enrollment model
class HbxEnrollment
  include Mongoid::Document
  include Mongoid::Timestamps

  ENROLLED_STATUSES = %w[coverage_selected transmitted_to_carrier coverage_enrolled coverage_termination_pending unverified coverage_reinstated].freeze
  TERMINATED_STATUSES = %w[coverage_terminated unverified coverage_expired].freeze
  CANCELED_STATUSES   = %w[coverage_canceled void].freeze # Void state enrollments are invalid enrollments. will be treated same as canceled.
  RENEWAL_STATUSES = %w[auto_renewing renewing_coverage_selected renewing_transmitted_to_carrier renewing_coverage_enrolled
                        auto_renewing_contingent renewing_contingent_selected renewing_contingent_transmitted_to_carrier
                        renewing_contingent_enrolled].freeze

  ENROLLED_AND_RENEWAL_STATUSES = ENROLLED_STATUSES + RENEWAL_STATUSES
  WAIVED_STATUSES     = %w(inactive renewing_waived)

  belongs_to :family

  field :is_any_enrollment_member_outstanding, type: Boolean, default: false

  field :coverage_household_id, type: String
  field :kind, type: String
  field :enrollment_kind, type: String, default: 'open_enrollment'
  field :coverage_kind, type: String, default: 'health'

  # FIXME: This unblocks people with legacy data where this field exists,
  #        preventing user registration as in #3394.  This is NOT a correct
  #        fix to that issue and it still needs to be addressed.
  field :elected_amount, type: Money, default: 0.0

  field :elected_premium_credit, type: Money, default: 0.0
  field :applied_premium_credit, type: Money, default: 0.0
  # TODO: need to understand these two fields
  field :elected_aptc_pct, type: Float, default: 0.0
  field :applied_aptc_amount, type: Money, default: 0.0
  field :aggregate_aptc_amount, type: Money, default: 0.0
  field :changing, type: Boolean, default: false

  field :effective_on, type: Date
  field :terminated_on, type: Date
  field :terminate_reason, type: String

  field :broker_agency_profile_id, type: BSON::ObjectId
  field :writing_agent_id, type: BSON::ObjectId
  field :employee_role_id, type: BSON::ObjectId
  field :benefit_group_id, type: BSON::ObjectId
  field :benefit_group_assignment_id, type: BSON::ObjectId
  field :hbx_id, type: String
  field :external_id, type: String
  field :external_group_identifiers, type: Array
  field :special_enrollment_period_id, type: BSON::ObjectId
  field :predecessor_enrollment_id, type: BSON::ObjectId
  field :enrollment_signature, type: String

  field :consumer_role_id, type: BSON::ObjectId
  field :resident_role_id, type: BSON::ObjectId
  # We will need to re-visit these names possibly, as we implement sponsored benefits.
  field :plan_id, type: BSON::ObjectId
  field :carrier_profile_id, type: BSON::ObjectId
  field :benefit_package_id, type: BSON::ObjectId
  field :benefit_coverage_period_id, type: BSON::ObjectId

  # Fields for new model
  field :benefit_sponsorship_id, type: BSON::ObjectId
  field :sponsored_benefit_package_id, type: BSON::ObjectId
  field :sponsored_benefit_id, type: BSON::ObjectId
  field :rating_area_id, type: BSON::ObjectId
  field :product_id, type: BSON::ObjectId
  field :issuer_profile_id, type: BSON::ObjectId

  field :original_application_type, type: String

  field :submitted_at, type: DateTime

  field :aasm_state, type: String
  field :aasm_state_date, type: Date    # Deprecated
  field :updated_by, type: String
  field :is_active, type: Boolean, default: true
  field :waiver_reason, type: String
  field :published_to_bus_at, type: DateTime
  field :review_status, type: String, default: "incomplete"
  field :special_verification_period, type: DateTime
  field :termination_submitted_on, type: DateTime

  embeds_many :hbx_enrollment_members

  scope :canceled, -> { where(:aasm_state.in => CANCELED_STATUSES) }
  scope :terminated,          ->{ where(:aasm_state.in => ["coverage_terminated", "coverage_termination_pending"]) }
  scope :canceled_and_terminated, -> { where(:aasm_state.in => (CANCELED_STATUSES + TERMINATED_STATUSES)) }
  scope :canceled_and_waived, -> { where(:aasm_state.in => (CANCELED_STATUSES + WAIVED_STATUSES)) }
  scope :renewing,            ->{ where(:aasm_state.in => RENEWAL_STATUSES )}
  scope :enrolled,             ->{ where(:aasm_state.in => ENROLLED_STATUSES) }
  scope :waived,              ->{ where(:aasm_state.in => WAIVED_STATUSES )}
  scope :expired,             ->{ where(:aasm_state => "coverage_expired")}
  scope :cancel_eligible,     ->{ where(:aasm_state.in => ["coverage_selected", "renewing_coverage_selected", "coverage_enrolled", "auto_renewing", "unverified"])}
  scope :enrolled_and_renewal, ->{where(:aasm_state.in => ENROLLED_AND_RENEWAL_STATUSES)}
  scope :enrolled_and_renewing, -> { where(:aasm_state.in => (ENROLLED_STATUSES + RENEWAL_STATUSES)) }
  scope :enrolled_waived_and_renewing, -> { where(:aasm_state.in => (ENROLLED_STATUSES + RENEWAL_STATUSES + WAIVED_STATUSES)) }
  scope :enrolled_and_renewing_and_shopping, -> { where(:aasm_state.in => (ENROLLED_STATUSES + RENEWAL_STATUSES + ['shopping'])) }
  scope :enrolled_and_renewing_and_expired, -> { where(:aasm_state.in => (ENROLLED_STATUSES + RENEWAL_STATUSES + ['coverage_expired'])) }
  scope :current_year,         ->{ where(:effective_on.gte => TimeKeeper.date_of_record.beginning_of_year, :effective_on.lte => TimeKeeper.date_of_record.end_of_year) }
  scope :individual_market,   ->{ where(:kind.nin => ["employer_sponsored", "employer_sponsored_cobra"]) }
  scope :by_health,           ->{where(coverage_kind: "health").order(effective_on: :desc)}
  scope :show_enrollments, -> { any_of([enrolled.selector, renewing.selector, terminated.selector, canceled.selector, waived.selector]) }
  scope :verification_needed, ->{ where(:is_any_enrollment_member_outstanding => true, :aasm_state.in => ENROLLED_STATUSES).or({:terminated_on => nil }, {:terminated_on.gt => TimeKeeper.date_of_record}).order(created_at: :desc) }

  def product=(new_product)
    if new_product.blank?
      self.product_id = nil
      @product = nil
      return
    end
    raise ArgumentError, "expected product" unless new_product.is_a?(BenefitMarkets::Products::Product)
    self.product_id = new_product._id
    @product = new_product
  end

  def product
    return @product if defined? @product
    @product = ::BenefitMarkets::Products::Product.find(self.product_id) unless product_id.blank?
  end
end
