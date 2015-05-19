class Person
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Versioning
  include Notify

  GENDER_KINDS = %W(male female)
  IDENTIFYING_INFO_ATTRIBUTES = %w(first_name last_name ssn dob)
  ADDRESS_CHANGE_ATTRIBUTES = %w(addresses phones emails)
  RELATIONSHIP_CHANGE_ATTRIBUTES = %w(person_relationships)

  field :hbx_id, type: String
  field :name_pfx, type: String
  field :first_name, type: String
  field :middle_name, type: String
  field :last_name, type: String
  field :name_sfx, type: String
  field :full_name, type: String
  field :alternate_name, type: String

  # Sub-model in-common attributes
  field :ssn, type: String
  field :dob, type: Date
  field :gender, type: String
  field :date_of_death, type: Date

  field :is_active, type: Boolean, default: true
  field :updated_by, type: String

  # Login account
  belongs_to :user

  belongs_to :employer_contact,
                class_name: "EmployerProfile",
                inverse_of: :employer_contacts,
                index: true

  belongs_to :broker_agency_contact,
                class_name: "BrokerAgencyProfile",
                inverse_of: :broker_agency_contacts,
                index: true

  embeds_one :consumer_role, cascade_callbacks: true, validate: true
  embeds_one :broker_role, cascade_callbacks: true, validate: true
  embeds_one :hbx_staff_role, cascade_callbacks: true, validate: true
  embeds_one :responsible_party, cascade_callbacks: true, validate: true

  embeds_many :employee_roles, cascade_callbacks: true, validate: true

  embeds_many :person_relationships, cascade_callbacks: true, validate: true
  embeds_many :addresses, cascade_callbacks: true, validate: true
  embeds_many :phones, cascade_callbacks: true, validate: true
  embeds_many :emails, cascade_callbacks: true, validate: true

  accepts_nested_attributes_for :consumer_role, :responsible_party, :broker_role, :hbx_staff_role,
    :person_relationships, :employee_roles, :addresses, :phones, :emails

  validates_presence_of :first_name, :last_name
  validate :date_functional_validations

  validates :ssn,
    length: { minimum: 9, maximum: 9, message: "SSN must be 9 digits" },
    numericality: true,
    uniqueness: true,
    allow_blank: true

  validates :gender,
    allow_blank: true,
    inclusion: { in: Person::GENDER_KINDS, message: "%{value} is not a valid gender" }


  before_save :update_full_name
  before_save :generate_hbx_id
  before_save :strip_empty_fields

  index({hbx_id: 1}, {sparse:true, unique: true})

  index({last_name:  1})
  index({first_name: 1})
  index({last_name: 1, first_name: 1})
  index({first_name: 1, last_name: 1})

  index({ssn: 1}, {sparse: true, unique: true})
  index({dob: 1}, {sparse: true})

  index({last_name: 1, dob: 1}, {sparse: true})

  # Broker child model indexes
  index({"broker_role._id" => 1})
  index({"broker_role.provider_kind" => 1})
  index({"broker_role.broker_agency_id" => 1})
  index({"broker_role.npn" => 1}, {sparse: true, unique: true})

  # Consumer child model indexes
  index({"consumer_role._id" => 1})
  index({"consumer_role.is_active" => 1})

  # Employee child model indexes
  index({"employee_roles._id" => 1})
  index({"employee_roles.employer_id" => 1})
  index({"employee_roles.census_family_id" => 1})
  index({"employee_roles.benefit_group_id" => 1})
  index({"employee_roles.is_active" => 1})

  # HbxStaff child model indexes
  index({"hbx_staff_role._id" => 1})
  index({"hbx_staff_role.is_active" => 1})

  # PersonRelationship child model indexes
  index({"person_relationship.relative_id" =>  1})

  scope :active,   ->{ where(is_active: true) }
  scope :inactive, ->{ where(is_active: false) }

  def generate_hbx_id
    if hbx_id.blank?
      hbx_id = HbxIdGenerator.generate
    end
  end

  def strip_empty_fields
    if ssn.blank?
      unset("ssn")
    end
  end

  # Strip non-numeric chars from ssn
  # SSN validation rules, see: http://www.ssa.gov/employer/randomizationfaqs.html#a0=12
  def ssn=(new_ssn)
    ssn_val = new_ssn.to_s.gsub(/\D/, '')
    if !new_ssn.blank?
      write_attribute(:ssn, new_ssn.to_s.gsub(/\D/, ''))
    else
      unset("ssn")
    end
  end

  def gender=(new_gender)
    write_attribute(:gender, new_gender.to_s.downcase)
  end

  def date_of_birth
    self.dob.blank? ? nil : self.dob.strftime("%m/%d/%Y")
  end

  def date_of_birth=(val)
    self.dob = Date.strptime(val, "%m/%d/%Y").to_date rescue nil
  end

  def primary_family
    Family.find_by_primary_applicant(self)
  end

  def get_employer_contact
    EmployerProfile.find(employer_contact_id) if employer_contact_id.present?
  end

  def families
    Family.find_all_by_person(self)
  end

  def full_name
    @full_name = [name_pfx, first_name, middle_name, last_name, name_sfx].compact.join(" ")
  end

  def age_on(date)
    age = date.year - dob.year
    if date.month < dob.month or (date.month == dob.month and date.day < dob.day)
      age - 1
    else
      age
    end
  end

 class << self

   # Find all employee_roles.  Since person has_many employee_roles, person may show up
   # employee_role.person may not be unique in returned set
   def employee_roles
     people = exists(:'employee_roles.0' => true).entries
     people.flat_map(&:employee_roles)
   end

  # Return an instance list of active People who match identifying information criteria
  def match_by_id_info(options)
    ssn_query = options[:ssn]
    dob_query = options[:dob]
    last_name = options[:last_name]

    raise ArgumentError, "must provide an ssn, last_name/dob or both" if (ssn_query.blank? && (dob_query.blank? || last_name.blank?))

    matches = Array.new
    matches.concat Person.active.where(ssn: ssn_query).to_a unless ssn_query.blank?
    matches.concat Person.where(last_name: last_name, dob: dob_query).active.to_a unless (dob_query.blank? || last_name.blank?)
    matches.uniq
  end

end

  def dob_to_string
    dob.blank? ? "" : dob.strftime("%Y%m%d")
  end

  def is_active?
    is_active
  end

  def find_relationship_with(other_person)
    if self.id == other_person.id
      "self"
    else
      person_relationship_for(other_person).try(:kind)
    end
  end

  def person_relationship_for(other_person)
    person_relationships.detect do |person_relationship|
      person_relationship.relative_id == other_person.id
    end
  end

  def self.match_existing_person(personish)
    return nil if personish.ssn.blank?
    Person.where(:ssn => personish.ssn, :dob => personish.dob).first
  end

  def ensure_relationship_with(person, relationship)
    existing_relationship = self.person_relationships.detect do |rel|
      rel.relative_id.to_s == person.id.to_s
    end
    if existing_relationship
      existing_relationship.update_attributes(:kind => relationship)
    else
      self.person_relationships << PersonRelationship.new({
        :kind => relationship,
        :relative_id => person.id
      })
    end
  end

  before_save :notify_change
  def notify_change
    notify_change_event(self, {"identifying_info"=>IDENTIFYING_INFO_ATTRIBUTES, "address_change"=>ADDRESS_CHANGE_ATTRIBUTES, "relation_change"=>RELATIONSHIP_CHANGE_ATTRIBUTES})
  end

  def relatives
    person_relationships.reject do |p_rel|
      p_rel.relative_id.to_s == self.id.to_s
    end.map(&:relative)
  end

private
  def update_full_name
    full_name
  end

  # Verify basic date rules
  def date_functional_validations
    date_of_birth_is_past
    date_of_death_is_blank_or_past
    date_of_death_follows_date_of_birth
  end

  def date_of_death_is_blank_or_past
    return unless self.date_of_death.present?
    errors.add(:date_of_death, "future date: %{self.date_of_death} is invalid date of death") if Date.today < self.date_of_death
  end

  def date_of_birth_is_past
    return unless self.dob.present?
    errors.add(:dob, "future date: %{self.dob} is invalid date of birth") if Date.today < self.dob
  end

  def date_of_death_follows_date_of_birth
    return unless self.date_of_death.present? && self.dob.present?

    if self.date_of_death < self.dob
      errors.add(:date_of_death, "date of death cannot preceed date of birth")
      errors.add(:dob, "date of birth cannot follow date of death")
    end
  end
end
