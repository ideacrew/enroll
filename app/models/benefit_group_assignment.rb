class BenefitGroupAssignment
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM

  RENEWING = %w(coverage_renewing)

  embedded_in :census_employee

  field :benefit_group_id, type: BSON::ObjectId

  # Represents the most recent completed enrollment
  field :hbx_enrollment_id, type: BSON::ObjectId

  field :start_on, type: Date
  field :end_on, type: Date
  field :coverage_end_on, type: Date
  field :aasm_state, type: String, default: "initialized"
  field :is_active, type: Boolean, default: true

  validates_presence_of :benefit_group_id, :start_on, :is_active
  validate :date_guards, :model_integrity

  scope :by_benefit_group_id, ->(benefit_group_id) {where(benefit_group_id: benefit_group_id)}
  scope :renewing,       ->{ any_in(aasm_state: RENEWING) }

  class << self
    def find(id)
      ee = CensusEmployee.where(:"benefit_group_assignments._id" => id).first
      ee.benefit_group_assignments.detect { |bga| bga._id == id } unless ee.blank?
    end

    def new_from_group_and_census_employee(benefit_group, census_ee)
      census_ee.benefit_group_assignments.new(
        benefit_group_id: benefit_group._id,
        start_on: [benefit_group.start_on, census_ee.hired_on].compact.max
      )
    end
  end

  def plan_year
    benefit_group.plan_year if benefit_group
  end

  def benefit_group=(new_benefit_group)
    raise ArgumentError.new("expected BenefitGroup") unless new_benefit_group.is_a? BenefitGroup
    self.benefit_group_id = new_benefit_group._id
    @benefit_group = new_benefit_group
  end

  def benefit_group
    return @benefit_group if defined? @benefit_group
    @benefit_group = BenefitGroup.find(self.benefit_group_id) unless benefit_group_id.blank?
  end

  def hbx_enrollment=(new_hbx_enrollment)
    raise ArgumentError.new("expected HbxEnrollment") unless new_hbx_enrollment.is_a? HbxEnrollment
    self.hbx_enrollment_id = new_hbx_enrollment._id
    @hbx_enrollment = new_hbx_enrollment
  end

  def hbx_enrollment
    return @hbx_enrollment if defined? @hbx_enrollment
    @hbx_enrollment = HbxEnrollment.find(self.hbx_enrollment_id) unless hbx_enrollment_id.blank?
  end

  def end_benefit(end_on)
    unless coverage_waived?
      self.coverage_end_on = end_on
      terminate_coverage
    end
  end

  aasm do
    state :initialized, initial: true
    state :coverage_selected
    state :coverage_waived
    state :coverage_terminated
    state :coverage_renewing

    #FIXME create new hbx_enrollment need to create a new benefitgroup_assignment
    #then we will not need from coverage_terminated to coverage_selected
    event :select_coverage do
      transitions from: [:initialized, :coverage_waived, :coverage_terminated, :coverage_renewing], to: :coverage_selected
    end

    event :waive_coverage do
      transitions from: [:initialized, :coverage_selected, :coverage_renewing], to: :coverage_waived
    end

    event :renew_coverage do 
      transitions from: :initialized , to: :coverage_renewing
    end

    event :terminate_coverage do
      transitions from: :coverage_selected, to: :coverage_terminated
      transitions from: :coverage_renewing, to: :coverage_terminated
    end

    event :delink_coverage do
      transitions from: [:coverage_selected, :coverage_waived, :coverage_terminated], to: :initialized, after: :propogate_delink
    end
  end

private
  def propogate_delink
    self.hbx_enrollment_id = nil
  end

  def model_integrity
    self.errors.add(:benefit_group, "benefit_group required") unless benefit_group.present?

    if coverage_selected?
      self.errors.add(:hbx_enrollment, "hbx_enrollment required") if hbx_enrollment.blank?
    end

    if hbx_enrollment.present?
      self.errors.add(:hbx_enrollment, "benefit group missmatch") unless hbx_enrollment.benefit_group_id == benefit_group_id
      self.errors.add(:hbx_enrollment, "employee_role missmatch") if hbx_enrollment.employee_role_id != census_employee.employee_role_id and census_employee.employee_role_linked?
    end
  end

  def date_guards
    return unless benefit_group.present? && start_on.present?

    unless (self.benefit_group.plan_year.start_on..self.benefit_group.plan_year.end_on).cover?(start_on)
      errors.add(:start_on, "can't occur outside plan year dates")
    end

    if end_on.present?
      unless (self.benefit_group.plan_year.start_on..self.benefit_group.plan_year.end_on).cover?(end_on)
        errors.add(:end_on, "can't occur outside plan year dates")
      end

      if end_on < start_on
        errors.add(:end_on, "can't occur before start date")
      end
    end
  end

end
