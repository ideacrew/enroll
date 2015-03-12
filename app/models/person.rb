class Person
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Versioning

# REMOVE "unknown" once data is corrected
  GENDER_KINDS = %W(male female unknown)

#  auto_increment :hbx_id, :seed => 9999

  field :hbx_id, type: Integer
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
  embeds_one :hbx_staff, cascade_callbacks: true, validate: true
  embeds_one :responsible_party, cascade_callbacks: true, validate: true

  embeds_many :employee_roles, cascade_callbacks: true, validate: true

  embeds_many :person_relationships, cascade_callbacks: true, validate: true
  embeds_many :addresses, cascade_callbacks: true, validate: true
  embeds_many :phones, cascade_callbacks: true, validate: true
  embeds_many :emails, cascade_callbacks: true, validate: true

  accepts_nested_attributes_for :consumer_role, :responsible_party, :broker_role, :hbx_staff,
    :person_relationships, :employee_roles, :addresses, :phones, :emails

  validates_presence_of :first_name, :last_name


# RE-ENABLE UNIQUNESS CHECK ONCE DATA IS CORRECTED
  validates :ssn,
    length: { minimum: 9, maximum: 9, message: "SSN must be 9 digits" },
    numericality: true,
#    uniqueness: true,
    allow_blank: true

  validates :gender,
    allow_blank: true,
    inclusion: { in: Person::GENDER_KINDS, message: "%{value} is not a valid gender" }

  before_save :update_full_name, :date_of_death_follows_date_of_birth

  index({hbx_id: 1}) #, {unique: true})
  index({last_name:  1})
  index({first_name: 1})
  index({last_name: 1, first_name: 1})
  index({first_name: 1, last_name: 1})
  index({ssn: 1}, {sparse: true}) # , unique: true})
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
  index({"hbx_staff._id" => 1})
  index({"hbx_staff.is_active" => 1})

  # PersonRelationship child model indexes
  index({"person_relationship.relative_id" =>  1})

  scope :active,   ->{ where(is_active: true) }
  scope :inactive, ->{ where(is_active: false) }

  # Strip non-numeric chars from ssn
  # SSN validation rules, see: http://www.ssa.gov/employer/randomizationfaqs.html#a0=12
  def ssn=(new_ssn)
    write_attribute(:ssn, new_ssn.to_s.gsub(/\D/, ''))
  end

  def gender=(new_gender)
    write_attribute(:gender, new_gender.to_s.downcase)
  end

  # def dob=(new_dob)
  #   bday = DateTime.strptime(new_dob, "%m-%d-%Y").to_date
  #   write_attribute(:dob, bday)
  # end

  def full_name
    @full_name = [name_pfx, first_name, middle_name, last_name, name_sfx].compact.join(" ")
  end

  def primary_family
    Family.find_by_primary_applicant(self)
  end

  def families
    Family.find_all_by_person(self)
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
    @dob.blank? ? "" : @dob.strftime("%Y%m%d")
  end

  def is_active?
    @is_active
  end

private
  def update_full_name
    full_name
  end

  def date_of_death_follows_date_of_birth
    return if date_of_death.nil? || dob.nil?
    errors.add(:date_of_death, "date of death cannot preceed date of birth") if date_of_death < dob
  end

end
