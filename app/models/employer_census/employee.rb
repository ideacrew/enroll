class EmployerCensus::Employee < EmployerCensus::Member

  embedded_in :family, class_name: "EmployerCensus::Family"

  field :date_of_hire, type: Date
  field :date_of_termination, type: Date

  validates_presence_of :ssn, :date_of_hire, :address

  validates :ssn,
    length: { minimum: 9, maximum: 9, message: "SSN must be 9 digits" },
    numericality: true

  def initialize(*args)
    super(*args)
    write_attribute(:employee_relationship, "self")
  end

end
