class EmployeeRoster
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :plan_year

  EMPLOYEE_RELATIONSHIP_KIND = %W[employee spouse dependent]

  field :family_id, type: String
  field :employee_relationship, type: String

  field :first_name, type: String
  field :middle_initial, type: String
  field :last_name, type: String
  field :name_sfx, type: String

  field :dob, type: Date
  field :date_of_hire, type: Date
  field :ssn, type: String

  validates_presence_of :first_name, :last_name

  validates :employee_relationship,
            presence: true,
            allow_blank: false,
            allow_nil:   false,
            inclusion: {in: EMPLOYEE_RELATIONSHIP_KIND, message: "%{value} is not a valid employee relationship"}

  validates :ssn,
    length: { minimum: 9, maximum: 9, message: "SSN must be 9 digits" },
    numericality: true,
    uniqueness: true

  def parent
    raise "undefined parent: Person" unless person?
    self.person
  end

  def broker=(broker_instance)
    return unless broker_instance.is_a? Broker
    self.broker_id = broker_instance._id
  end

  def broker
    Broker.find(self.broker_id) unless self.broker_id.blank?
  end

  embeds_one :address
  embeds_one :email

end
