class EmployerCensusFamily
  include Mongoid::Document

  embedded_in :employer

  field :is_active, type: Boolean, default: true

  # embeds_one :employer_census_member
  embeds_one :employer_census_employee, 
    cascade_callbacks: true,
    validate: true
  embeds_many :employer_census_dependents, 
    cascade_callbacks: true,
    validate: true

  validates_presence_of :employer_census_employee

  scope :active, ->{ where(:is_active => true) }

  def is_active?
    self.is_active
  end

end
