class EmployerCensus::EmployeeFamily

  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :employer

  field :plan_year_id, type: BSON::ObjectId
  field :benefit_group_id, type: BSON::ObjectId

  # UserID that connected and timestamp
  field :linked_person_id, type: BSON::ObjectId
  field :linked_employee_id, type: BSON::ObjectId
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

  scope :active,     ->{ where(:terminated => false) }
  scope :terminated, ->{ where(:terminated => true) }

  scope :linked,     ->{ where(:is_linked => true) }
  scope :unlinked,   ->{ where(:is_linked => false) }

  # Initialize a new, refreshed instance for rehires via deep copy
  def clone
    new_family = self.dup
    new_family.linked_person_id = nil
    new_family.linked_employee_id = nil
    new_family.linked_at = nil
    new_family.terminated = false

    new_family.census_dependents = self.census_dependents unless self.census_dependents.blank?
      
    if self.census_employee.present?
      new_family.census_employee = self.census_employee
      new_family.census_employee.hired_on = nil
      new_family.census_employee.terminated_on = nil
    end

    new_family
  end

  def parent
    raise "undefined parent Employer" unless employer?
    self.employer
  end

  def plan_year=(new_plan_year)
    parent.households.where(:irs_group_id => self.id)
  end

  def plan_year
    return if plan_year.blank?
    parent.plan_years.find(self.plan_year_id)
  end

  def benefit_group=(new_benefit_group)
  end

  def benefit_group
    parent.plan_year.benefit_group.find(:plan_year_id => self.plan_year_id)
  end

  def link_employee(employee)
    raise EmployeeFamilyLinkError.new(employee) if is_linked?
    self.linked_person_id = employee.person._id
    self.linked_employee_id = employee._id
    self.linked_at = Time.now
    self
  end

  def delink_employee
    self.linked_person_id = nil
    self.linked_employee_id = nil
    self.linked_at = nil
    self
  end

  def linked_employee
    if is_linked?
      p = Person.find(linked_person_id)
      es = p.employees
      e = es.find(linked_employee_id)
    end
  end

  def is_linked?
    self.linked_employee_id.present? && self.linked_person_id.present?
  end

  def terminate(last_day_of_work)
    self.employee.terminated_on = date
    self.terminated = true
    self
  end

  def is_terminated?
    self.terminated
  end

end

class EmployeeFamilyLinkError < StandardError
  def initialize(person)
    @person = person
    super("employee_family already linked to person #{person.inspect}")
  end
end
