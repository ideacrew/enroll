class HbxEnrollment
  include Mongoid::Document
  include Mongoid::Timestamps
  include HasFamilyMembers
  include AASM

  # Persists result of a completed plan shopping process

  Kinds = %W[unassisted_qhp insurance_assisted_qhp employer_sponsored streamlined_medicaid emergency_medicaid hcr_chip]
  Authority = [:open_enrollment ]

  embedded_in :household

  field :coverage_household_id, type: String
  field :kind, type: String

  field :elected_premium_credit, type: Money, default: 0.0
  field :applied_premium_credit, type: Money, default: 0.0

  field :effective_on, type: Date
  field :terminated_on, type: Date

  field :plan_id, type: BSON::ObjectId
  field :broker_agency_id, type: BSON::ObjectId
  field :writing_agent_id, type: BSON::ObjectId
  field :employer_profile_id, type: BSON::ObjectId
  field :benefit_group_id, type: BSON::ObjectId

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

  # FIXME: Not even close to correct
  def subscriber
    hbx_enrollment_members.first
  end

  def family
    household.family if household.present?
  end

  def applicant_ids
    hbx_enrollment_members.map(&:applicant_id)
  end

  def employer_profile=(employer_instance)
    self.employer_profile_id = employer_instance._id if employer_instance.is_a? EmployerProfile
  end

  def employer_profile
    EmployerProfile.find(self.employer_profile_id) unless self.employer_profile_id.blank?
  end

  def broker_agency_profile=(new_broker_agency)
    return if new_broker_agency.blank?
    self.broker_agency_id = new_broker._id
  end

  def broker_agency_profile
    return unless has_broker_agency?
    parent.broker_agency.find(self.broker_agency_id)
  end

  def benefit_group=(benefit_group)
    self.benefit_group_id = benefit_group._id if benefit_group.is_a? BenefitGroup
  end

  def benefit_group
    BenefitGroup.find(self.benefit_group_id) unless self.benefit_group_id.blank?
  end

  def has_broker_agency?
    broker_agency_id.present?
  end

  # TODO: Fix this to properly respect mulitiple possible employee roles for the same employer
  #       This should probably be done by comparing the hired_on date with todays date.
  #       Also needs to ignore any that were already terminated before a certain date.
  def self.calculate_start_date_from(employer_profile, coverage_household, benefit_group)
    employee_role = coverage_household.subscriber.family_member.person.employee_roles.detect do |e_role|
      e_role.employer_profile_id.to_s == employer_profile.id.to_s
    end
    benefit_group.effective_on_for(employee_role.hired_on)
  end

  def self.new_from(employer_profile: nil, coverage_household:, benefit_group:)
    enrollment = HbxEnrollment.new
    enrollment.household = coverage_household.household
    enrollment.kind = "employer_sponsored" if employer_profile.present?
    enrollment.employer_profile = employer_profile
    enrollment.effective_on = calculate_start_date_from(employer_profile, coverage_household, benefit_group)
    # benefit_group.plan_year.start_on
    enrollment.benefit_group = benefit_group
    coverage_household.coverage_household_members.each do |coverage_member|
      enrollment_member = HbxEnrollmentMember.new_from(coverage_household_member: coverage_member)
      enrollment_member.eligibility_date = enrollment.effective_on
      enrollment_member.coverage_start_on = enrollment.effective_on
      enrollment.hbx_enrollment_members << enrollment_member
    end
    enrollment
  end

  def self.create_from(employer_profile: nil, coverage_household:, benefit_group:)
    enrollment = self.new_from(
      employer_profile: employer_profile,
      coverage_household: coverage_household,
      benefit_group: benefit_group
    )
    enrollment.save
    enrollment
  end
end
