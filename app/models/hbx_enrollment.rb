require 'ostruct'

class HbxEnrollment
  include Mongoid::Document
  include Mongoid::Timestamps
  include HasFamilyMembers
  include AASM
  include MongoidSupport::AssociationProxies

  Kinds = %W[unassisted_qhp insurance_assisted_qhp employer_sponsored streamlined_medicaid emergency_medicaid hcr_chip]
  Authority = [:open_enrollment]
  WAIVER_REASONS = [
    "I have coverage through spouse’s employer health plan",
    "I have coverage through parent’s employer health plan",
    "I have coverage through any other employer health plan",
    "I have coverage through an individual market health plan",
    "I have coverage through Medicare",
    "I have coverage through Tricare",
    "I have coverage through Medicaid",
    "I do not have other coverage"
  ]

  embedded_in :household

  field :coverage_household_id, type: String
  field :kind, type: String

  field :elected_premium_credit, type: Money, default: 0.0
  field :applied_premium_credit, type: Money, default: 0.0

  field :effective_on, type: Date
  field :terminated_on, type: Date

  field :plan_id, type: BSON::ObjectId
  field :broker_agency_profile_id, type: BSON::ObjectId
  field :writing_agent_id, type: BSON::ObjectId
  field :employee_role_id, type: BSON::ObjectId
  field :benefit_group_id, type: BSON::ObjectId
  field :benefit_group_assignment_id, type: BSON::ObjectId

  field :submitted_at, type: DateTime

  field :aasm_state, type: String
  field :aasm_state_date, type: Date
  field :updated_by, type: String
  field :is_active, type: Boolean, default: true
  field :waiver_reason, type: String

  associated_with_one :benefit_group, :benefit_group_id, "BenefitGroup"
  associated_with_one :benefit_group_assignment, :benefit_group_assignment_id, "BenefitGroupAssignment"
  associated_with_one :employee_role, :employee_role_id, "EmployeeRole"

  delegate :total_premium, :total_employer_contribution, :total_employee_cost, to: :decorated_hbx_enrollment, allow_nil: true

  scope :active, ->{ where(is_active: true).where(:created_at.ne => nil) }

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
    state :shopping, initial: true
    state :coverage_selected
    state :enrollment_transmitted_to_carrier
    state :coverage_enrolled      # effectuated

    state :coverage_canceled      # coverage never took effect
    state :coverage_terminated    # coverage ended

    state :inactive   # :after_enter inform census_employee

    event :waive_coverage do
      transitions from: [:shopping, :coverage_selected], to: :inactive, after: :propogate_waiver
    end

    event :select_coverage do
      transitions from: :shopping, to: :coverage_selected, after: :propogate_selection
    end

    event :terminate_coverage do
      transitions from: :coverage_selected, to: :coverage_terminated, after: :propogate_terminate
    end
  end

  def propogate_terminate
    self.terminated_on = TimeKeeper.date_of_record.end_of_month
    if benefit_group_assignment
      benefit_group_assignment.end_benefit(TimeKeeper.date_of_record.end_of_month)
      benefit_group_assignment.save
    end
  end

  def propogate_waiver
    benefit_group_assignment.waive_coverage! if benefit_group_assignment
  end

  def propogate_selection
    if benefit_group_assignment
      benefit_group_assignment.select_coverage unless benefit_group_assignment.coverage_selected?
      benefit_group_assignment.hbx_enrollment = self
      benefit_group_assignment.save
    end
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

  def plan=(new_plan)
    raise ArgumentError.new("expected Plan") unless new_plan.is_a? Plan
    self.plan_id = new_plan._id
    @plan = new_plan
  end

  def plan
    return @plan if defined? @plan
    @plan = Plan.find(self.plan_id) unless plan_id.blank?
  end

  def broker_agency_profile=(new_broker_agency_profile)
    raise ArgumentError.new("expected BrokerAgencyProfile") unless new_broker_agency_profile.is_a? BrokerAgencyProfile
    self.broker_agency_profile_id = new_broker_agency_profile._id
    @broker_agency_profile = new_broker_agency_profile
  end

  def broker_agency_profile
    return @broker_agency_profile if defined? @broker_agency_profile
    @broker_agency_profile = BrokerAgencyProfile.find(self.broker_agency_profile_id) unless broker_agency_profile_id.blank?
  end

  def has_broker_agency_profile?
    broker_agency_profile_id.present?
  end

  def can_complete_shopping?
    household.family.is_eligible_to_enroll?
  end

  def humanized_dependent_summary
    hbx_enrollment_members.count - 1
  end

  def rebuild_members_by_coverage_household(coverage_household:)
    applicant_ids = hbx_enrollment_members.map(&:applicant_id)
    coverage_household.coverage_household_members.each do |coverage_member|
      next if applicant_ids.include? coverage_member.family_member_id
      enrollment_member = HbxEnrollmentMember.new_from(coverage_household_member: coverage_member)
      enrollment_member.eligibility_date = self.effective_on
      enrollment_member.coverage_start_on = self.effective_on
      self.hbx_enrollment_members << enrollment_member
    end
    self
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
    census_employee = employee_role.census_employee
    benefit_group_assignment = census_employee.benefit_group_assignments.by_benefit_group_id(benefit_group.id).first
    enrollment.benefit_group_assignment_id = benefit_group_assignment.id
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

  def self.find_by_benefit_groups(benefit_groups = [])
    id_list = benefit_groups.collect(&:_id).uniq

    families = nil
    if id_list.size == 1
      families = Family.where(:"households.hbx_enrollments.benefit_group_id" => id_list.first)
    else
      families = Family.any_in(:"households.hbx_enrollments.benefit_group_id" => id_list )
    end

    enrollment_list = []
    families.each do |family|
      family.households.each do |household|
        household.hbx_enrollments.each do |enrollment|
          enrollment_list << enrollment if id_list.include?(enrollment.benefit_group_id)
        end
      end
    end
    enrollment_list
  end

  def self.find_by_benefit_group_assignments(benefit_group_assignments = [])
    id_list = benefit_group_assignments.collect(&:_id)

    families = nil
    if id_list.size == 1
      families = Family.where(:"households.hbx_enrollments.benefit_group_assignment_id" => id_list.first)
    else
      families = Family.any_in(:"households.hbx_enrollments.benefit_group_assignment_id" => id_list )
    end

    enrollment_list = []
    families.each do |family|
      family.households.each do |household|
        household.hbx_enrollments.each do |enrollment|
          enrollment_list << enrollment if id_list.include?(enrollment.benefit_group_assignment_id)
        end
      end
    end
    enrollment_list
  end

  private

  def decorated_hbx_enrollment
    if plan.present? && benefit_group.present?
      PlanCostDecorator.new(plan, self, benefit_group, benefit_group.reference_plan)
    else
      OpenStruct.new(:total_premium => 0.00, :total_employer_contribution => 0.00, :total_employee_cost => 0.00)
    end
  end
end
