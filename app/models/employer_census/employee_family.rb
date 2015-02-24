class EmployerCensus::EmployeeFamily
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :employer

  field :plan_year_id, type: BSON::ObjectId
  field :benefit_group_id, type: BSON::ObjectId

  # UserID that connected and timestamp
  field :linked_person_id, type: BSON::ObjectId
  field :linked_at, type: DateTime

  field :terminated, type: Boolean, default: false

  embeds_one :employee,
    class_name: "EmployerCensus::Employee",
    cascade_callbacks: true,
    validate: true
  accepts_nested_attributes_for :employee, reject_if: :all_blank, allow_destroy: true

  embeds_many :dependents,
    class_name: "EmployerCensus::Dependent",
    cascade_callbacks: true,
    validate: true
  accepts_nested_attributes_for :dependents, reject_if: :all_blank, allow_destroy: true

  validates_presence_of :employee

  scope :active,     ->{ where(:terminated => false) }
  scope :terminated, ->{ where(:terminated => true) }

  scope :linked,     ->{ where("linked_at <= ?", Time.now) }
  scope :unlinked,   ->{ where(:linked_at.blank? ) }

  # Create a copy of this instance for rehires into same ER
  def clone
    copy = self.dup
    copy.linked_person_id = nil
    copy.linked_at = nil
    copy.employee.hired_on = nil
    copy.employee.terminated_on = nil
    copy
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

  def link_person(person)
    raise EmployeeFamilyLinkError.new(person) if is_linked?
    self.linked_person_id = person._id
    self.linked_at = ->{ Time.now }
  end

  def delink_person
    self.linked_person_id = nil
    self.linked_at = nil
  end  

  def linked_person
    Person.find(self.linked_person_id) unless linked_person_id.blank?
  end

  def is_linked?
    self.linked_person_id.present?
  end

  def terminate(last_day_of_work)
    self.employee.terminated_on = date
    self.terminated = true
  end

  def is_terminated?
    self.terminated
  end

end

class < EmployeeFamilyLinkError < StandardError
  def initialize(person)
    @person = person
    super("employee_family already linked to person #{person.inspect}")
  end
end

