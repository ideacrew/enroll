class Person
  include Mongoid::Document
  include Mongoid::Timestamps

  # extend Mongorder

  field :hbx_assigned_id, type: String      # Enterprise-level unique ID for this person

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
  field :death_date, type: Date

  field :is_active, type: Boolean, default: true
  field :updated_by, type: String

  # Login account
  has_one :user, as: :profile, dependent: :destroy

  # belongs_to :employer_representatives, class_name: "Employer",  inverse_of: :representatives

  embeds_many :consumers
  embeds_many :employees
  embeds_many :brokers
  embeds_many :hbx_staffs

  embeds_many :addresses
  accepts_nested_attributes_for :addresses, reject_if: proc { |attribs| attribs['address_1'].blank? }, allow_destroy: true

  embeds_many :phones
  accepts_nested_attributes_for :phones, reject_if: proc { |attribs| attribs['phone_number'].blank? }, allow_destroy: true

  embeds_many :emails
  accepts_nested_attributes_for :emails, reject_if: proc { |attribs| attribs['email_address'].blank? }, allow_destroy: true

  embeds_many :person_relationships
  accepts_nested_attributes_for :person_relationships

  before_save :initialize_name_full, :death_date_follows_birth_date

  validates_presence_of :first_name, :last_name

  validates :ssn, 
            allow_blank: true,
            length: { is: 9, message: "SSN must be 9 digits" }, 
            numericality: true


  index({hbx_assigned_id: 1}, {unique: true})
  index({ssn: 1}, {sparse: true, unique: true})
  index({last_name:  1})
  index({first_name: 1})
  index({last_name: 1, first_name: 1})
  index({first_name: 1, last_name:1})


  scope :active,   ->{ where(is_active: true) }
  scope :inactive, ->{ where(is_active: false) }

  def self.find_employees_by_employer(employer_instance)
    return unless employer_instance.is_a? Employer
    where("employees.employer_id" =>  employer_instance._id).to_a
  end

  # Strip non-numeric chars from ssn
  # SSN validation rules, see: http://www.ssa.gov/employer/randomizationfaqs.html#a0=12
  def ssn=(val)
    return if val.blank?
    write_attribute(:ssn, val.to_s.gsub(/[^0-9]/i, ''))
  end

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


  def self.default_search_order
    [
      ["last_name", 1],
      ["first_name", 1]
    ]
  end

  def full_name
    [name_pfx, first_name, middle_name, last_name, name_sfx].reject(&:blank?).join(' ').downcase.gsub(/\b\w/) {|first| first.upcase }
  end

  def merge_address(m_address)
    unless (self.addresses.any? { |p| p.match(m_address) })
      self.addresses << m_address
    end
  end

  def update_address(m_address)
    existing_address = self.addresses.select { |p| p.address_type == m_address.address_type }
    existing_address.each do |ep|
      self.addresses.delete(ep)
    end
    self.addresses << m_address
    self.touch
  end

  def remove_address_of(address_type)
    existing_address = self.addresses.detect { |p| p.address_type == address_type }
    if existing_address
      existing_address.destroy
    end
    self.touch
  end

  def merge_email(m_email)
    unless (self.emails.any? { |p| p.match(m_email) })
      self.emails << m_email
    end
  end

  def update_email(m_email)
    existing_email = self.emails.select { |p| p.email_type == m_email.email_type }
    existing_email.each do |ep|
      self.emails.delete(ep)
    end
    self.emails << m_email
    self.touch
  end

  def merge_phone(m_phone)
    unless (self.phones.any? { |p| p.match(m_phone) })
      self.phones << m_phone
    end
  end

  def update_phone(m_phone)
    existing_phones = self.phones.select { |p| p.phone_type == m_phone.phone_type }
    existing_phones.each do |ep|
      self.phones.delete(ep)
    end
    self.phones << m_phone
    self.touch
  end

  def addresses_match?(other_person)
    my_home_addresses = addresses.select(&:home?)
    other_home_addresses = other_person.addresses.select(&:home?)
    return(false) if (my_home_addresses.length != other_home_addresses.length)
    my_home_addresses.all? do |m_addy|
      other_home_addresses.any? { |o_addy| o_addy.match(m_addy) }
    end
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

private

  def initialize_name_full
    self.name_full = full_name
  end

  def death_date_follows_birth_date
    return if death_date.nil? || dob.nil?
    errors.add(:death_date, "death_date cannot preceed dob") if death_date < dob
  end



end
