class EmployerCensus::Employee < EmployerCensus::Member

  embedded_in :employee_family, class_name: "EmployerCensus::EmployeeFamily"

  field :hired_on, type: Date
  field :terminated_on, type: Date

  validates_presence_of :ssn, :dob, :hired_on

  def initialize(*args)
    super(*args)
    write_attribute(:employee_relationship, "self")
  end

end
