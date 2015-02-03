class Person
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic
  
  GENDER_KINDS = %W(male female)

  # TODO: Need simpler, Enterprise-level incrementing ID
  # field :hbx_assigned_id, type: Integer 

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

  belongs_to :employer_representatives, class_name: "Employer",  inverse_of: :representatives
  belongs_to :family

  embeds_one :consumer, cascade_callbacks: true, validate: true
  embeds_one :employee, cascade_callbacks: true, validate: true
  embeds_one :broker, cascade_callbacks: true, validate: true
  embeds_one :hbx_staff, cascade_callbacks: true, validate: true
  embeds_one :responsible_party, cascade_callbacks: true, validate: true

  embeds_many :person_relationships, cascade_callbacks: true, validate: true
  embeds_many :addresses, cascade_callbacks: true, validate: true
  embeds_many :phones, cascade_callbacks: true, validate: true
  embeds_many :emails, cascade_callbacks: true, validate: true
  
  #building non person relation using through relation
  # has_many :broker_family_members, class_name: "FamilyMember", :inverse_of => :broker
  # has_many :employee_family_members, class_name: "FamilyMember", :inverse_of => :employee

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

  before_save :initialize_name_full, :date_of_death_follows_date_of_birth

  index({hbx_assigned_id: 1}, {unique: true})
  index({last_name:  1})
  index({first_name: 1})
  index({last_name: 1, first_name: 1})
  index({first_name: 1, last_name: 1})
  index({ssn: 1}, {sparse: true, unique: true})
  index({dob: 1}, {sparse: true})
  index({last_name: 1, dob: 1}, {sparse: true})

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
  def ssn=(new_ssn)
    return if new_ssn.blank?
    write_attribute(:ssn, new_ssn.to_s.gsub(/[^0-9]/i, ''))
  end

  def gender=(new_gender)
    return if new_gender.blank?
    write_attribute(:gender, new_gender.downcase)
  end

  # def dob=(new_dob)
  #   bday = DateTime.strptime(new_dob, "%m-%d-%Y").to_date
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
  
  # May include multiple active employees
  # def employees=()
  # end

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

  def full_name
    [name_pfx, first_name, middle_name, last_name, name_sfx].reject(&:blank?).join(' ').downcase.gsub(/\b\w/) {|first| first.upcase }
  end

  # Return an instance list of active People who match identifying information criteria
  def self.match_by_id_info(options)
    ssn = options[:ssn]
    dob = options[:dob]
    last_name = options[:last_name]

    raise ArgumentError, "must provide an ssn, last_name/dob or both" if (ssn.blank? && (dob.blank? || last_name.blank?))

    matches = []
    matches.concat Person.where(ssn: ssn).active.to_a unless ssn.blank?
    matches.concat Person.where(last_name: last_name).active.and(dob: dob).to_a unless (dob.blank? || last_name.blank?)
    matches.uniq
  end

  def dob_to_string
    self.dob.blank? ? "" : self.dob.strftime("%Y%m%d")
  end

  def is_active?
    self.is_active
  end
  
private
  def initialize_name_full
    # self.name_full = full_name
  end

  def date_of_death_follows_date_of_birth
    return if date_of_death.nil? || dob.nil?
    errors.add(:date_of_death, "date of death cannot preceed date of birth") if date_of_death < dob
  end

  def safe_downcase(value)
    value.blank? ? value : value.downcase.strip
  end
end
