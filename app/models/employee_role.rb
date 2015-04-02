class EmployeeRole
  include Mongoid::Document
  include Mongoid::Timestamps

  EMPLOYMENT_STATUS_KINDS   = ["active", "full-time", "part-time", "retired", "terminated"]

  embedded_in :person

  field :employer_profile_id, type: BSON::ObjectId
  field :census_family_id, type: BSON::ObjectId
  field :benefit_group_id, type: BSON::ObjectId
  field :employment_status, type: String
  field :hired_on, type: Date
  field :terminated_on, type: Date
  field :is_active, type: Boolean, default: true

  delegate :hbx_id, to: :person, allow_nil: true
  delegate :ssn, :ssn=, to: :person, allow_nil: true
  delegate :dob, :dob=, to: :person, allow_nil: true
  delegate :gender, :gender=, to: :person, allow_nil: true

  validates_presence_of :ssn, :dob, :gender, :employer_profile_id, :hired_on

  accepts_nested_attributes_for :person

  embeds_one :inbox, as: :recipient

  after_create :create_inbox
  before_save :termination_date_must_follow_hire_date

  # hacky fix for nested attributes
  # TODO: remove this when it is no longer needed
  after_initialize do |employee_role|
    if employee_role.person.present?
      @changed_nested_person_attributes = {}
      %w[ssn dob gender hbx_id].each do |field|
        if employee_role.person.send("#{field}_changed?")
          @changed_nested_person_attributes[field] = employee_role.person.send(field)
        end
      end
    end
    true
  end
  after_build do |employee_role|
    if employee_role.person.present? && @changed_nested_person_attributes.present?
      employee_role.person.update_attributes(@changed_nested_person_attributes)
      unset @changed_nested_person_attributes
    end
    true
  end


  ## TODO: propogate to EmployerCensus updates to employee demographics and family

  def families
    Family.by_employee(self)
  end

  # def self.find_by_employer_profile(profile)
  #   # return unless profile.is_a? EmployerProfile
  #   where("employer_profile_id" =>  profile._id).to_a
  # end

  # belongs_to Employer
  def employer_profile=(new_employer)
    raise ArgumentError.new("expected EmployerProfile") unless new_employer.is_a? EmployerProfile
    self.employer_profile_id = new_employer._id
  end

  def employer_profile
    EmployerProfile.find(self.employer_profile_id)
  end

  # belongs_to BenefitGroup
  def benefit_group=(new_benefit_group)
    raise ArgumentError.new("expected BenefitGroup class") unless new_benefit_group.is_a? BenefitGroup
    self.benefit_group_id = new_benefit_group._id
  end

  def benefit_group
    benefit_group.find(self.benefit_group_id) unless benefit_group_id.blank?
  end

  def census_family
    EmployerCensus::EmployeeFamily.find_by_employee_role(self)
  end

  def is_active?
    self.is_active
  end

  def self.find(employee_role_id)
    bson_id = BSON::ObjectId.from_string(employee_role_id)
    person = Person.where({"employee_roles._id" => bson_id })
    person.first.employee_roles.detect { |ee| ee.id == bson_id } unless person.size < 1
  end

  def self.list(collection)
    collection.reduce([]) { |elements, person| elements << person.send(klass) }
  end

  # TODO; return as chainable Mongoid::Criteria
  def self.all
    # criteria = Mongoid::Criteria.new(Person)
    list Person.exists(klass.to_sym => true)
  end

  def self.first
    self.all.first
  end

private
  def create_inbox
    welcome_subject = "Welcome to DC HealthLink"
    welcome_body = "DC HealthLink is the District of Columbia's on-line marketplace to shop, compare, and select health insurance that meets your health needs and budgets."
    mailbox = Inbox.create(recipient: self)
    mailbox.messages.create(subject: welcome_subject, body: welcome_body)
  end

  def self.klass
    self.to_s.downcase
  end

  def termination_date_must_follow_hire_date
    return if hired_on.nil? || terminated_on.nil?
    errors.add(:terminated_on, "terminated_on cannot preceed hired_on") if terminated_on < hired_on
  end
end
