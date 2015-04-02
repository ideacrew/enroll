class EmployerCensus::EmployeeFamily

  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :employer_profile

  field :plan_year_id, type: BSON::ObjectId
  field :benefit_group_id, type: BSON::ObjectId

  # UserID that connected and timestamp
  field :employee_role_id, type: BSON::ObjectId
  field :linked_at, type: DateTime

  field :terminated, type: Boolean, default: false

  embeds_one :census_employee,
    class_name: "EmployerCensus::Employee",
    cascade_callbacks: true,
    validate: true
  accepts_nested_attributes_for :census_employee, reject_if: :all_blank, allow_destroy: true

  embeds_many :census_dependents,
    class_name: "EmployerCensus::Dependent",
    cascade_callbacks: true,
    validate: true
  accepts_nested_attributes_for :census_dependents, reject_if: :all_blank, allow_destroy: true

  validates_presence_of :census_employee

  default_scope  ->{ where(:terminated => false) }
  scope :terminated,     ->{ where(:terminated => true) }

  scope :linked,     ->{ where(:is_linked => true) }
  scope :unlinked,   ->{ where(:is_linked => false) }

  # Initialize a new, refreshed instance for rehires via deep copy
  def replicate_for_rehire
    new_family = self.dup
    new_family.delink_employee_role
    new_family.terminated = false

    if self.census_employee.present?
      new_family.census_employee = self.census_employee
      new_family.census_employee.hired_on = nil
      new_family.census_employee.terminated_on = nil
    end

    new_family.census_dependents = self.census_dependents unless self.census_dependents.blank?
    new_family
  end

  def parent
    raise "undefined parent EmployerProfile" unless employer_profile?
    self.employer_profile
  end

  def plan_year=(new_plan_year)
    self.plan_year_id = new_plan_year._id unless new_plan_year.blank?
  end

  def plan_year
    return if plan_year.blank?
    parent.plan_years.find(self.plan_year_id)
  end

  def benefit_group=(new_benefit_group)
    if new_benefit_group.present?
      self.benefit_group_id = new_benefit_group._id
      self.plan_year = new_benefit_group.plan_year
    end
  end

  def benefit_group
    parent.plan_years.find(plan_year_id).benefit_groups.find(benefit_group_id)
  end

  def link_employee_role(new_employee_role)
    raise EmployeeFamilyLinkError, "already linked to an employee role" if is_linked?
    raise EmployeeFamilyLinkError, "invalid to link a terminated employee" if is_terminated?

    self.employee_role_id = new_employee_role._id
    self.linked_at = Time.now
    self
  end

  def linked_employee_role
    EmployeeRole.find(self.employee_role_id) if is_linked?
  end

  def delink_employee_role
    self.employee_role_id = nil
    self.linked_at = nil
    self
  end

  def is_linked?
    self.employee_role_id.present?
  end

  def is_linkable?
    (is_linked? == false) && (is_terminated? == false)
  end

  def terminate(last_day_of_work)
    begin
      terminate!(last_day_of_work)
    rescue
      nil
    else
      self
    end
  end

  def terminate!(last_day_of_work)
    coverage_term_date = last_day_of_work.end_of_month

    max_retro_term = HbxProfile::ShopRetroactiveTerminationMaximumInDays
    if (Date.today - coverage_term_date) > max_retro_term
      message =  "Error while terminating: #{census_employee.first_name} #{census_employee.last_name} (id=#{id}). "
      message << "Termination date: #{last_day_of_work.end_of_month} exceeds maximum period "
      message << "(#{HbxProfile::ShopRetroactiveTerminationMaximumInDays} days) for a retroactive termination"
      Rails.logger.error { message }
      raise HbxPolicyError, message
    end

    self.census_employee.terminated_on = coverage_term_date
    self.terminated = true
    self
  end

  def is_terminated?
    self.terminated
  end

  class << self
    def find_by_employee_role(employee_role)
      organizations = Organization.where("employer_profile.employee_families.employee_role_id" => employee_role._id).to_a
      return nil if organizations.size != 1
      organizations.first.employer_profile.employee_families.detect { | family | family.employee_role_id == employee_role._id }
    end
  end

private
  # Apply business rules for when an enrollment -- outside open enrollment -- is considered timely, including:
  # Number of days preceeding effective date that an employee may submit a plan enrollment
  # Minimum number of days an employee may submit a plan, following addition or correction to Employer roster

  def is_timely_special_enrollment?
    # Employee has
  end
end

class EmployeeFamilyLinkError < StandardError; end
