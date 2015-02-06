class Employee
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :person

  field :employer_id, type: BSON::ObjectId
  field :benefit_group_id, type: BSON::ObjectId
  field :date_of_hire, type: Date
  field :date_of_termination, type: Date
  field :is_active, type: Boolean, default: true

  delegate :hbx_id, to: :person, allow_nil: true
  delegate :ssn, :ssn=, to: :person, allow_nil: true
  delegate :dob, :dob=, to: :person, allow_nil: true
  delegate :gender, :gender=, to: :person, allow_nil: true

  validates_presence_of :person, :ssn, :dob, :gender, :employer_id, :date_of_hire

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
    return unless new_employer.is_a? Employer
    self.employer_id = new_employer._id
  end

  def employer
    Employer.find(self.employer_id) unless employer_id.blank?
  end

  # belongs_to BenefitGroup
  def benefit_group=(new_benefit_group)
    return unless new_benefit_group.is_a? BenefitGroup
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
    return if date_of_hire.nil? || date_of_termination.nil?
    errors.add(:date_of_termination, "date_of_termination cannot preceed date_of_hire") if date_of_termination < date_of_hire
  end
end
