class EmployerCensus::Employee < EmployerCensus::Member
  embedded_in :employee_family, class_name: "EmployerCensus::EmployeeFamily", inverse_of: :census_employee

  field :hired_on, type: Date
  field :terminated_on, type: Date
  field :is_owner, type: Boolean

  validates_presence_of :ssn, :dob, :hired_on

  def initialize(*args)
    super(*args)
    write_attribute(:employee_relationship, "self")
  end

  def is_linkable?
    return false if employee_family.blank?
    employee_family.is_linkable?
  end

  def is_owner?
    is_owner
  end

end
