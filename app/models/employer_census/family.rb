class EmployerCensus::Family
  include Mongoid::Document

  embedded_in :employer

  field :is_active, type: Boolean, default: true

  embeds_one :employee,
    class_name: "EmployerCensus::Employee",
    cascade_callbacks: true,
    validate: true
  embeds_many :dependents,
    class_name: "EmployerCensus::Dependent",
    cascade_callbacks: true,
    validate: true
  embeds_many :members,
    class_name: "EmployerCensus::Member",
    cascade_callbacks: true

  validates_presence_of :employee

  scope :active, ->{ where(:is_active => true) }

  def is_active?
    self.is_active
  end

end
