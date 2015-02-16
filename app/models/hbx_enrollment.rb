class HbxEnrollment
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM

  # Persists result of a completed plan shopping process

  KINDS = %W[unassisted_qhp insurance_assisted_qhp employer_sponsored streamlined_medicaid emergency_medicaid hcr_chip]

  embedded_in :household

  field :kind, type: String
  field :enrollment_group_id, type: String
  field :applied_aptc_in_cents, type: Integer, default: 0
  field :elected_aptc_in_cents, type: Integer, default: 0
  field :is_active, type: Boolean, default: true
  field :submitted_at, type: DateTime
  field :aasm_state, type: String
  field :policy_id, type: Integer
  field :employer_id, type: BSON::ObjectId

  field :broker_agency_id, type: BSON::ObjectId

  embeds_many :hbx_enrollment_members

  include HasFamilyMembers

  embeds_many :comments
  accepts_nested_attributes_for :comments, reject_if: proc { |attribs| attribs['content'].blank? }, allow_destroy: true

  validates :kind,
    					presence: true,
    					allow_blank: false,
    					allow_nil:   false,
    					inclusion: {in: KINDS, message: "%{value} is not a valid enrollment type"}

  validates :applied_aptc_in_cents,
              allow_nil: true,
              numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validates :elected_aptc_in_cents,
              allow_nil: true,
              numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def policy=(policy_instance)
    return unless policy_instance.is_a? Policy
    self.policy_id = policy_instance._id
  end

  def policy
    Policy.find(self.policy_id) unless self.policy_id.blank?
  end

  def applied_aptc_in_dollars=(dollars)
    self.applied_aptc_in_cents = (Rational(dollars) * Rational(100)).to_i
  end

  def applied_aptc_in_dollars
    (Rational(applied_aptc_in_cents) / Rational(100)).to_f if applied_aptc_in_cents
  end

  def elected_aptc_in_dollars=(dollars)
    self.elected_aptc_in_cents = (Rational(dollars) * Rational(100)).to_i
  end

  def elected_aptc_in_dollars
    (Rational(elected_aptc_in_cents) / Rational(100)).to_f if elected_aptc_in_cents
  end

  aasm do
    state :enrollment_closed, initial: true
  end

  def is_active?
    self.is_active
  end

  def family
    return nil unless household
    household.family
  end

  def applicant_ids
    hbx_enrollment_members.map(&:applicant_id)
  end

  def employer=(employer_instance)
    return unless employer_instance.is_a? Employer
    self.employer_id = employer_instance._id
  end

  def employer
    Employer.find(self.employer_id) unless self.employer_id.blank?
  end

  def broker_agency=(new_broker_agency)
    return if new_broker_agency.blank?
    self.broker_agency_id = new_broker._id
  end

  def broker_agency
    return unless has_broker_agency?
    parent.broker_agency.find(self.broker_agency_id)
  end

  def has_broker_agency?
    !broker_agency_id.blank?
  end
end
