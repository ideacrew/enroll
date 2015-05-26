class CensusFamily
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM

  embedded_in :census_roster

  field :aasm_state, type: String

  # Flag indicating CensusEmployee is active on this EmployerProfile
  field :is_terminated, type: Boolean, default: false

  # EmployeerRole linked to this census family
  field :employee_role_id, type: BSON::ObjectId

  # Flag indicating this census family is associated with an EmployeeRole
  field :is_linked, type: Boolean, default: false

  # Timestamp when this CensusFamily was associated with an EmployeeRole
  field :linked_at, type: DateTime

  field :coverage_terminated_on, type: Date

  field :employer_profile_id, type: BSON::ObjectId

  delegate :ssn, :dob, to: :census_employee, prefix: true
  delegate :hired_on, :terminated_on, to: :census_employee

  embeds_one :census_employee,
    cascade_callbacks: true,
    validate: true
  accepts_nested_attributes_for :census_employee, reject_if: :all_blank, allow_destroy: true

  embeds_many :census_dependents,
    cascade_callbacks: true,
    validate: true
  accepts_nested_attributes_for :census_dependents, reject_if: :all_blank, allow_destroy: true

  embeds_many :benefit_group_assignments,
    class_name: "EmployerCensus::BenefitGroupAssignment",
    cascade_callbacks: true,
    validate: true
  accepts_nested_attributes_for :benefit_group_assignments, reject_if: :all_blank, allow_destroy: true

  validates_presence_of :census_employee

  default_scope          ->{ where(:is_terminated => false) }
  scope :is_terminated,  ->{ where(:is_terminated => true) }

  scope :is_linked,      ->{ where(:is_linked => true) }
  scope :not_linked,     ->{ where(:is_linked => false) }

  scope :order_by_last_name, ->  { order(:"census_employee.last_name".asc) }
  scope :order_by_first_name, -> { order(:"census_employee.first_name".asc) }

  def parent
    raise "undefined parent EmployerProfile" unless employer_profile?
    self.employer_profile
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

  def employee_role=(new_employee_role)
    raise ArgumentError, "expected EmployeeRole" unless new_employee_role.is_a? EmployeeRole
    self.employee_role_id = new_employee_role._id
    @employee_role = new_employee_role
    self.is_linked = true
  end

  def employee_role
    return @employee_role if is_defined? @employee_role
    @employee_role = EmployeeRole.find(self.employee_role_id) unless self.employee_role_id.blank?
  end

  # Initialize a new, refreshed instance for rehires via deep copy
  def replicate_for_rehire
    return nil if is_active?  # if user clicks on rehire again after creating an active family.
    new_family = self.dup
    new_family.delink_employee_role
    new_family.is_terminated = false

    if self.census_employee.present?
      # new_family.census_employee = self.census_employee
      new_family.census_employee.hired_on = nil
      new_family.census_employee.terminated_on = nil
    end

    # new_family.census_dependents = self.census_dependents unless self.census_dependents.blank?
    new_family
  end

  # Family is in active state. find_census_families_by_person returns [nil] if not present, so using compact
  def is_active?
    EmployerProfile.find_census_families_by_person(census_employee).compact.present?
  end

  def link_employee_role(employee_role, linked_at = DateTime.current)
    raise CensusFamilyLinkError, "invalid to link a terminated employee" if is_terminated?
    raise CensusFamilyLinkError, "must assign a benefit group" unless active_benefit_group_assignment.present?

    @linked_employee_role = employee_role
    self.employee_role_id = employee_role._id
    self.linked_at = linked_at
    employee_role.census_family_id = _id
    self
  end

  def linked_employee_role
    return @linked_employee_role if defined? @linked_employee_role
    @linked_employee_role = EmployeeRole.find(self.employee_role_id) if is_linked?
  end

  def delink_employee_role
    @linked_employee_role = nil
    self.employee_role_id = nil
    self.linked_at = nil
    self.is_linked = false
    self
  end

  def is_linked?
    self.employee_role_id.present?
  end

  def is_linkable?
    (is_linked? == false) && (is_terminated? == false) && active_benefit_group_assignment.present?
  end

  def terminate(terminated_on)
    begin
      terminate!(terminated_on)
    rescue
      nil
    else
      self
    end
  end

  def terminate!(terminated_on)
    coverage_term_date = terminated_on.to_date.end_of_month

    max_retro_term = HbxProfile::ShopRetroactiveTerminationMaximumInDays
    if (Date.today - coverage_term_date) > max_retro_term
      message =  "Error while terminating: #{census_employee.first_name} #{census_employee.last_name} (id=#{id}). "
      message << "Termination date: #{terminated_on.end_of_month} exceeds maximum period "
      message << "(#{HbxProfile::ShopRetroactiveTerminationMaximumInDays} days) for a retroactive termination"
      Rails.logger.error { message }
      raise HbxPolicyError, message
    end

    self.coverage_terminated_on = coverage_term_date
    self.is_terminated = true
    self
  end

  def is_terminated?
    self.is_terminated
  end

  class << self
    def find_by_employee_role(employee_role)
      organizations = Organization.where("employer_profile.employee_families.employee_role_id" => employee_role._id).to_a
      return nil if organizations.size != 1
      organizations.first.employer_profile.employee_families.unscoped.detect { | family | family.employee_role_id == employee_role._id }
    end

    def find(id)
      organizations = Organization.where("employer_profile.employee_families._id" => BSON::ObjectId.from_string(id))
      organizations.size > 0 ? organizations.first.employer_profile.employee_families.unscoped.detect { |family| family._id.to_s == id.to_s} : nil
    end
  end


  # Workflow for automatic approval
  aasm do
    state :eligible, initial: true
    state :enrolled
    state :coverage_waived
    state :employment_is_terminated

    event :enroll do
      transitions from: [:eligible, :coverage_waived], to: [:enrolled]
    end

    event :waive_coverage do
      transitions from: [:eligible, :enrolled], to: [:coverage_waived]
    end

    event :terminate_employment do
      transitions from: [:eligible, :enrolled, :coverage_waived], to: [:employment_is_terminated]
    end
  end

  def active_benefit_group_id
    return(nil) unless active_benefit_group_assignment
    active_benefit_group_assignment.benefit_group_id
  end


private
  # Apply business rules for when an enrollment -- outside open enrollment -- is considered timely, including:
  # Number of days preceeding effective date that an employee may submit a plan enrollment
  # Minimum number of days an employee may submit a plan, following addition or correction to Employer roster

  def is_timely_special_enrollment?
    # Employee has
  end
end

class CensusFamilyLinkError < StandardError; end