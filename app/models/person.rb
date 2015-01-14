class Person
  # require 'autoinc'
  include Mongoid::Document
  include Mongoid::Timestamps
  # include Mongoid::Autoinc

  GENDER_KINDS = %W(male female unknown)
  CHILD_MODELS = [
      :consumer, :responsible_party, :broker, :hbx_staff, :person_relationships, :employees,
      :addresses, :phones, :emails
    ]

  # Enterprise-level unique ID for this person
  field :hbx_assigned_id, type: Integer
  # increments :hbx_assigned_id, seed: 9999

  field :name_pfx, type: String, default: ""
  field :first_name, type: String
  field :middle_name, type: String, default: ""
  field :last_name, type: String
  field :name_sfx, type: String, default: ""
  field :name_full, type: String
  field :alternate_name, type: String, default: ""

  # Sub-model in-common attributes
  field :ssn, type: String
  field :dob, type: Date
  field :gender, type: String
  field :date_of_death, type: Date

  field :is_active, type: Boolean, default: true
  field :updated_by, type: String
  field :subscriber_type, type: String
  
  # Login account
  has_one :user, as: :profile, dependent: :destroy

  # belongs_to :employer_representatives, class_name: "Employer",  inverse_of: :representatives

  embeds_one :consumer
  embeds_one :employee
  embeds_one :responsible_party
  embeds_one :broker
  embeds_one :hbx_staff

  embeds_many :person_relationships
  embeds_many :addresses
  embeds_many :phones
  embeds_many :emails

  accepts_nested_attributes_for :consumer, :responsible_party, :broker, :hbx_staff,
    :person_relationships, :employee, :addresses, :phones, :emails

  validates_presence_of :first_name, :last_name

  validates :ssn,
    length: { minimum: 9, maximum: 9, message: "SSN must be 9 digits" },
    numericality: true,
    uniqueness: true,
    allow_blank: true

  validates :gender,
    allow_blank: true,
    inclusion: { in: GENDER_KINDS, message: "%{value} is not a valid gender" }

  # validates_each CHILD_MODELS do | record, attrib, value |
  #   record.errors.add(attrib)
  # end

  before_save :initialize_name_full, :date_of_death_follows_birth_date

  index({hbx_assigned_id: 1}, {unique: true})
  index({last_name:  1})
  index({first_name: 1})
  index({last_name: 1, first_name: 1})
  index({first_name: 1, last_name:1})
  index({ssn: 1}, {sparse: true, unique: true})
  index({dob: 1}, {sparse: true, unique: true})

  # Broker child model indexes
  index({"broker._id" => 1})
  index({"broker.kind" => 1})
  index({"broker.hbx_assigned_id" => 1})
  index({"broker.npn" => 1})

  # Consumer child model indexes
  index({"consumer._id" => 1})
  index({"consumer.is_active" => 1})

  # Employee child model indexes
  index({"employee._id" => 1})
  index({"employee.employer_id" => 1})
  index({"employee.is_active" => 1})

  # HbxStaff child model indexes
  index({"hbx_staff._id" => 1})
  index({"hbx_staff.is_active" => 1})

  # PersonRelationship child model indexes
  index({"person_relationship.relative_id" =>  1})

  scope :active,   ->{ where(is_active: true) }
  scope :inactive, ->{ where(is_active: false) }

  # Strip non-numeric chars from ssn
  # SSN validation rules, see: http://www.ssa.gov/employer/randomizationfaqs.html#a0=12
  def ssn=(val)
    return if val.blank?
    write_attribute(:ssn, val.to_s.gsub(/[^0-9]/i, ''))
  end

  def gender=(val)
    return if val.blank?
    write_attribute(:gender, val.downcase)
  end

  # def dob=(val)
  #   bday = DateTime.strptime(val, "%m-%d-%Y").to_date
  #   write_attribute(:dob, bday)
  # end

  def families
    Family.where(:family_member.person_id => self.id).to_a
  end

  def update_attributes_with_delta(props = {})
    old_record = self.find(self.id)
    self.assign_attributes(props)
    delta = self.changes_with_embedded
    return false unless self.valid?
    # As long as we call right here, whatever needs to be notified,
    # with the following three arguments:
    # - the old record
    # - the properties to update ("props")
    # - the delta ("delta")
    # We have everything we need to construct whatever messages care about that data.
    # E.g. (again, ignore the naming as it is terrible)
    #Protocols::Notifier.update_notification(old_record, props, delta)
    Protocols::Notifier.update_notification(old_record, delta) #The above statement was giving error with 3 params

    # Then we proceed normally
    self.update_attributes(props)
  end

  def home_address
    addresses.detect { |adr| adr.kind == "home" }
  end

  def mailing_address
    addresses.detect { |adr| adr.kind == "mailing" } || home_address
  end

  def billing_address
    addresses.detect { |adr| adr.kind == "billing" } || home_address
  end

  def home_phone
    phones.detect { |phone| phone.kind == "home" }
  end

  def home_email
    emails.detect { |email| email.kind == "home" }
  end

  def can_edit_family_address?
    associated_ids = associated_for_address
    return(true) if associated_ids.length < 2
    Person.find(associated_ids).combination(2).all? do |addr_set|
      addr_set.first.addresses_match?(addr_set.last)
    end
  end
  
  def subscriber
    abs_subscriber = nil
    case self.subscriber_type
    when "employee"
      abs_subscriber = self.employee
    when "broker"
      abs_subscriber =  self.broker
    when "consumer"
      abs_subscriber =  self.consumer
    end
    return abs_subscriber
  end
  
  def subscriber=(subscriber_hash)
    abs_subscriber = nil
    case self.subscriber_type
    when "employee"
      self.employee = subscriber_hash
    when "broker" 
      self.broker = subscriber_hash
    when "consumer"
      self.consumer = subscriber_hash
    end
    
  end

  def is_active?
    self.is_active
  end

private
  def initialize_name_full
    #self.name_full = full_name
  end

  def date_of_death_follows_birth_date
    return if date_of_death.nil? || dob.nil?
    errors.add(:date_of_death, "date_of_death cannot preceed dob") if date_of_death < dob
  end

  def dob_string
    self.dob.blank? ? "" : self.dob.strftime("%Y%m%d")
  end

  def safe_downcase(val)
    val.blank? ? val : val.downcase.strip
  end
end
