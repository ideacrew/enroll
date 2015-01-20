class EmployerCensusEmployee < EmployerCensusMember

  embedded_in :employer_census_family

  field :date_of_hire, type: Date
  field :date_of_termination, type: Date

  validates_presence_of :ssn, :date_of_hire, :address

  def initialize(*args)
    super(*args)
    write_attribute(:employee_relationship, "self")
  end

end
