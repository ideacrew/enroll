class HbxEnrollment
  include Mongoid::Document
  include Mongoid::Timestamps
  include HasFamilyMembers
  include AASM

  # Persists result of a completed plan shopping process

  Kinds = %W[unassisted_qhp insurance_assisted_qhp employer_sponsored streamlined_medicaid emergency_medicaid hcr_chip]
  Authority = [:open_enrollment ]

  embedded_in :household

  field :enrollment_group_id, type: String
  field :kind, type: String

  field :policy_id, type: String

  field :elected_premium_credit, type: Money, default: 0.0
  field :applied_premium_credit, type: Money, default: 0.0

  field :plan_id, type: BSON::ObjectId
  field :effective_on, type: Date
  field :terminated_on, type: Date

  field :broker_agency_id, type: BSON::ObjectId
  field :writing_agent_id, type: BSON::ObjectId

  field :submitted_at, type: DateTime

  field :aasm_state, type: String
  field :aasm_state_date, type: Date
  field :updated_by, type: String
  field :is_active, type: Boolean, default: true


  embeds_many :hbx_enrollment_members
  accepts_nested_attributes_for :hbx_enrollment_members, reject_if: :all_blank, allow_destroy: true

  embeds_many :comments
  accepts_nested_attributes_for :comments, reject_if: proc { |attribs| attribs['content'].blank? }, allow_destroy: true

  validates :kind,
    					presence: true,
    					allow_blank: false,
    					allow_nil:   false,
    					inclusion: {in: Kinds, message: "%{value} is not a valid enrollment type"}


  def policy=(new_policy)
    return unless new_policy.is_a? Policy
    self.policy_id = new_policy._id
  end

  def policy
    Policy.find(self.policy_id) unless self.policy_id.blank?
  end

  aasm do
    state :applying, initial: true
    state :submitted
    state :transmitted_to_carrier
    state :carrier_processing
    state :plan_effectuated
    state :plan_canceled
    state :plan_terminated
  end

  def is_active?
    self.is_active
  end

  def family
    household.family if household.present?
  end

  def applicant_ids
    hbx_enrollment_members.map(&:applicant_id)
  end

  def employer_profile=(employer_instance)
    return unless employer_instance.is_a? EmployerProfile
    self.employer_id = employer_instance._id
  end

  def employer_profile
    Employer.find(self.employer_id) unless self.employer_id.blank?
  end

  def broker_agency_profile=(new_broker_agency)
    return if new_broker_agency.blank?
    self.broker_agency_id = new_broker._id
  end

  def broker_agency_profile
    return unless has_broker_agency?
    parent.broker_agency.find(self.broker_agency_id)
  end

  def has_broker_agency?
    broker_agency_id.present?
  end
end
