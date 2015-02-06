class EmployerCensus::Family
  include Mongoid::Document

  embedded_in :employer


  field :matched_at, type: DateTime
  field :is_active, type: Boolean, default: true

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

  embeds_many :members,
    class_name: "EmployerCensus::Member",
    cascade_callbacks: true
  accepts_nested_attributes_for :members, reject_if: :all_blank, allow_destroy: true

  validates_presence_of :employee

  scope :active, ->{ where(:is_active => true) }

  # Create a copy of this instance for rehires into same organization
  def clone
    copy = self.dup
    copy.employee.date_of_hire = nil
    copy.employee.date_of_termination = nil
    copy.matched_at = nil
    copy.is_active = true
    copy
  end

  def is_active?
    self.is_active
  end

end
