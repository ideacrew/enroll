class CensusEmployee < CensusMember
  include AASM
  include Sortable

  field :is_business_owner, type: Boolean
  field :hired_on, type: Date
  field :employment_terminated_on, type: Date
  field :coverage_terminated_on, type: Date
  field :aasm_state, type: String

  # Employer for this employee
  field :employer_profile_id, type: BSON::ObjectId

  # Employee linked to this roster record
  field :employee_role_id, type: BSON::ObjectId

  embeds_many :census_dependents,
    cascade_callbacks: true,
    validate: true

  embeds_many :benefit_group_assignments,
    class_name: "EmployerCensus::BenefitGroupAssignment",
    cascade_callbacks: true,
    validate: true

  accepts_nested_attributes_for :census_dependents, :benefit_group_assignments

  validates_presence_of :employer_profile_id, :ssn, :dob, :hired_on, :is_business_owner

  index({"aasm_state" => 1})
  index({"employer_profile_id" => 1}, {sparse: true})
  index({"employee_role_id" => 1}, {sparse: true})
  index({"benefit_group_assignments._id" => 1})
  index({"last_name" => 1})
  index({"hired_on" => 1})
  index({"is_business_owner" => 1})
  index({"ssn" => 1})
  index({"dob" => 1})
  index({"ssn" => 1, "dob" => 1})


  scope :active,  ->{ any_in(aasm_state: ["unlinked", "linked", "enrolled", "coverage_waived", "coverage_terminated"]) }

  def initialize(*args)
    super(*args)
    write_attribute(:employee_relationship, "self")
  end

  def employer_profile=(new_employer_profile)
    raise ArgumentError.new("expected EmployerProfile") unless new_employer_profile.is_a?(EmployerProfile)
    self.employer_profile_id = new_employer_profile._id
    @employer_profile = new_employer_profile
  end

  def employer_profile
    return @employer_profile if is_defined? @employer_profile
    @employer_profile = EmployerProfile.find(self.employer_profile_id) unless self.employer_profile_id.blank?
  end

  def employee_role
    return @employee_role if is_defined? @employee_role
    @employee_role = EmployeeRole.find(self.employee_role_id) unless self.employee_role_id.blank?
  end

  def add_benefit_group_assignment(new_benefit_group_assignment)
    raise ArgumentError, "expected valid BenefitGroupAssignment" unless new_benefit_group_assignment.valid?
    if active_benefit_group_assignment
      active_benefit_group_assignment.end_on = [new_benefit_group_assignment.start_on - 1.day, active_benefit_group_assignment.start_on].max
      active_benefit_group_assignment.is_active = false
    end

    benefit_group_assignments << new_benefit_group_assignment
  end

  def active_benefit_group_assignment
    benefit_group_assignments.detect { |assignment| assignment.is_active? }
  end

  def inactive_benefit_group_assignments
    benefit_group_assignments.reject(&:is_active?)
  end

  # Initialize a new, refreshed instance for rehires via deep copy
  def replicate_for_rehire
    return nil if is_active?  # if user clicks on rehire again after creating an active family.
    new_employee = self.dup
    new_employee.unlink_employee_role
    new_employee.aasm_state = unlinked
    new_employee.hired_on = nil
    new_employee.employment_terminated_on = nil
    new_employee.coverage_terminated_on = nil

    # new_employee.census_dependents = self.census_dependents unless self.census_dependents.blank?
    new_employee
  end

  def is_linkable?
    self.unlinked?
  end

  def is_business_owner?
    is_business_owner
  end

  class << self
    def find_by_identifiers(ssn, dob)
      where(ssn: ssn).and(dob: dob).first
    end

    def find_by_employer_profile(employer_profile)
      where(employer_profile_id: employer_profile._id).unscoped.order_name_desc
    end

    def find_by_employee_role(employee_role)
      where(employee_role_id: employee_role_.id)
    end
  end


  aasm do
    state :unlinked, initial: true
    state :linked
    state :employment_terminated

    state :coverage_selected
    state :coverage_waived

    event :link_employee_role do
      transitions from: :unlinked, to: :linked
    end

    event :unlink_employee_role do
      transitions from: :linked, to: :unlinked
    end

    event :enroll do
      transitions from: :linked, to: :coverage_selected
      transitions from: :coverage_waived, to: :coverage_selected
    end

    event :waive_coverage do
      transitions from: :linked, to: :coverage_waived
      transitions from: :coverage_selected, to: :coverage_waived
    end

    event :terminate_coverage do
      transitions from: :coverage_selected, to: :coverage_terminated
    end

    event :terminate_employment do
      transitions from: [:linked, ], to: :employment_terminated
    end

  end

private

  def link_employee_role(new_employee_role)
    raise ArgumentError.new("expected EmployeeRole") unless new_employee_role.is_a? EmployeeRole
    raise CensusEmployeeLinkError, "must assign a benefit group" unless active_benefit_group_assignment.present?

    self.employee_role_id = employee_role._id
    @employee_role = new_employee_role
    self
  end

  def unlink_employee_role
    self.employee_role_id = nil
    @employee_role = nil
    self
  end

  def terminate_employment(terminated_on)
    begin
      terminate!(terminated_on)
    rescue
      nil
    else
      self
    end
  end

  def terminate_employment!(terminated_on)
    coverage_term_date = terminated_on.to_date.end_of_month

    retro_term_maximum = HbxProfile::ShopRetroactiveTerminationMaximumInDays
    if (Date.today - coverage_term_date) > retro_term_maximum
      message =  "Error while terminating: #{first_name} #{last_name} (id=#{id}). "
      message << "Termination date: #{terminated_on.end_of_month} exceeds maximum period "
      message << "(#{retro_term_maximum} days) for a retroactive termination"
      Rails.logger.error { message }
      raise HbxPolicyError, message
    end

    self.coverage_terminated_on = coverage_term_date
    self.is_terminated = true
    self
  end

end

class CensusEmployeeLinkError < StandardError; end

