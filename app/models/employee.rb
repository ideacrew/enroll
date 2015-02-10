class Employee
  include Mongoid::Document
  include Mongoid::Timestamps

  EMPLOYMENT_STATUS_KINDS   = ["active", "full-time", "part-time", "retired", "terminated"]

  embedded_in :person

  field :employer_id, type: BSON::ObjectId
  field :benefit_group_id, type: BSON::ObjectId
  field :employee_status, type: String
  field :hired_on, type: Date
  field :terminated_on, type: Date
  field :is_active, type: Boolean, default: true

  delegate :hbx_id, to: :person, allow_nil: true
  delegate :ssn, :ssn=, to: :person, allow_nil: true
  delegate :dob, :dob=, to: :person, allow_nil: true
  delegate :gender, :gender=, to: :person, allow_nil: true

  validates_presence_of :person, :ssn, :dob, :gender, :employer_id, :hired_on

  before_save :termination_date_must_follow_hire_date

  validates :ssn,
    length: { minimum: 9, maximum: 9, message: "Employee SSN must be 9 digits" },
    numericality: true,
    uniqueness: true

  def families
    Family.by_employee(self)
  end

  # def self.find_by_employer(employer_instance)
  #   # return unless employer_instance.is_a? Employer 
  #   where("employer_id" =>  employer_instance._id).to_a
  # end

  # belongs_to Employer
  def employer=(new_employer)
    raise ArgumentError.new("expected Employer class") unless new_employer.is_a? Employer
    self.employer_id = new_employer._id
  end

  def employer
    Employer.find(self.employer_id) unless employer_id.blank?
  end

  # belongs_to BenefitGroup
  def benefit_group=(new_benefit_group)
    raise ArgumentError.new("expected BenefitGroup class") unless new_benefit_group.is_a? BenefitGroup
    self.benefit_group_id = new_benefit_group._id
  end

  def benefit_group
    benefit_group.find(self.benefit_group_id) unless benefit_group_id.blank?
  end

  def is_active?
    self.is_active
  end

private
  def termination_date_must_follow_hire_date
    return if hired_on.nil? || terminated_on.nil?
    errors.add(:terminated_on, "terminated_on cannot preceed hired_on") if terminated_on < hired_on
  end
end
