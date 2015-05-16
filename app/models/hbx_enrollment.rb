class HbxEnrollment
  include Mongoid::Document
  include Mongoid::Timestamps
  include HasFamilyMembers
  include AASM
  include MongoidSupport::AssociationProxies

  # Persists result of a completed plan shopping process

  Kinds = %W[unassisted_qhp insurance_assisted_qhp employer_sponsored streamlined_medicaid emergency_medicaid hcr_chip]
  Authority = [:open_enrollment]

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
  field :employee_role_id, type: BSON::ObjectId
  field :benefit_group_id, type: BSON::ObjectId

  field :submitted_at, type: DateTime

  field :aasm_state, type: String
  field :aasm_state_date, type: Date
  field :updated_by, type: String
  field :is_active, type: Boolean, default: true

  associated_with_one :benefit_group, :benefit_group_id, "BenefitGroup"
  associated_with_one :employee_role, :employee_role_id, "EmployeeRole"


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

  def subscriber
    hbx_enrollment_members.detect(&:is_subscriber)
  end

  def family
    household.family if household.present?
  end

  def applicant_ids
    hbx_enrollment_members.map(&:applicant_id)
  end

  def employer_profile
    employee_role.employer_profile
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

  def can_complete_shopping?(t_date = Date.today)
    return false unless benefit_group
    benefit_group.within_new_hire_window?(employee_role.hired_on)
  end

  # TODO: Fix this to properly respect mulitiple possible employee roles for the same employer
  #       This should probably be done by comparing the hired_on date with todays date.
  #       Also needs to ignore any that were already terminated before a certain date.
  def self.calculate_start_date_from(employee_role, coverage_household, benefit_group)
    benefit_group.effective_on_for(employee_role.hired_on)
  end

  def self.new_from(employee_role: nil, coverage_household:, benefit_group:)
    enrollment = HbxEnrollment.new
    enrollment.household = coverage_household.household
    enrollment.kind = "employer_sponsored" if employee_role.present?
    enrollment.employee_role = employee_role
    enrollment.effective_on = calculate_start_date_from(employee_role, coverage_household, benefit_group)
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

  def self.create_from(employee_role: nil, coverage_household:, benefit_group:)
    enrollment = self.new_from(
      employee_role: employee_role,
      coverage_household: coverage_household,
      benefit_group: benefit_group
    )
    enrollment.save
    enrollment
  end

  def self.find(id)
    id = BSON::ObjectId.from_string(id) if id.is_a? String
    families = Family.where({
      "households.hbx_enrollments._id" => id
    })
    found_value = catch(:found) do
      families.each do |family|
        family.households.each do |household|
          household.hbx_enrollments.each do |enrollment|
            if enrollment.id == id
              throw :found, enrollment
            end
          end
        end
      end
      raise Mongoid::Errors::DocumentNotFound.new(self, id)
    end
    return found_value
  end
end
