# frozen_string_literal: true

class HbxEnrollment
  include Mongoid::Document
  include Mongoid::Timestamps

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
  # TODO need to understand these two fields
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

end
