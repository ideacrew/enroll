class Person
  include Mongoid::Document
  include Mongoid::Timestamps
  # include SetCurrentUser

  GENDER_KINDS = %W(male female)
  IDENTIFYING_INFO_ATTRIBUTES = %w(first_name last_name ssn dob)
  ADDRESS_CHANGE_ATTRIBUTES = %w(addresses phones emails)
  RELATIONSHIP_CHANGE_ATTRIBUTES = %w(person_relationships)

  PERSON_CREATED_EVENT_NAME = "acapi.info.events.individual.created"
  PERSON_UPDATED_EVENT_NAME = "acapi.info.events.individual.updated"
  VERIFICATION_TYPES = ['Social Security Number', 'American Indian Status', 'Citizenship', 'Immigration status']

  field :hbx_id, type: String
  field :name_pfx, type: String
  field :first_name, type: String
  field :middle_name, type: String
  field :last_name, type: String
  field :name_sfx, type: String
  field :full_name, type: String
  field :alternate_name, type: String

  # Sub-model in-common attributes
  field :encrypted_ssn, type: String
  field :dob, type: Date
  field :gender, type: String
  field :date_of_death, type: Date
  field :dob_check, type: Boolean

  field :is_incarcerated, type: Boolean

  field :is_disabled, type: Boolean
  field :ethnicity, type: Array
  field :race, type: String
  field :tribal_id, type: String

  field :is_tobacco_user, type: String, default: "unknown"
  field :language_code, type: String

  field :no_dc_address, type: Boolean, default: false
  field :no_dc_address_reason, type: String, default: ""

  field :is_active, type: Boolean, default: true
  field :updated_by, type: String
  field :no_ssn, type: String #ConsumerRole TODO TODOJF
  field :is_physically_disabled, type: Boolean

  delegate :is_applying_coverage, to: :consumer_role, allow_nil: true

  # Login account
  belongs_to :user, optional: true

  embeds_many :employee_roles, cascade_callbacks: true, validate: true
  embeds_one :consumer_role, cascade_callbacks: true, validate: true
  embeds_one :broker_role, cascade_callbacks: true, validate: true
  embeds_one :csr_role, cascade_callbacks: true, validate: true
  embeds_one :assister_role, cascade_callbacks: true, validate: true
  embeds_one :hbx_staff_role, cascade_callbacks: true, validate: true
  embeds_many :broker_agency_staff_roles, cascade_callbacks: true, validate: true
  embeds_many :general_agency_staff_roles, cascade_callbacks: true, validate: true
  embeds_many :employer_staff_roles, cascade_callbacks: true, validate: true
  embeds_many :addresses, cascade_callbacks: true, validate: true
  embeds_many :phones, cascade_callbacks: true, validate: true
  embeds_many :emails, cascade_callbacks: true, validate: true
  embeds_one :inbox, as: :recipient

  accepts_nested_attributes_for :phones, :reject_if => Proc.new { |addy| Phone.new(addy).blank? }
  accepts_nested_attributes_for :addresses, :reject_if => Proc.new { |addy| Address.new(addy).blank? }
  accepts_nested_attributes_for :emails, :reject_if => Proc.new { |addy| Email.new(addy).blank? }
  accepts_nested_attributes_for :broker_role

  validates_presence_of :first_name, :last_name
  validate :date_functional_validations
  validate :no_changing_my_user, :on => :update

  validates :ssn,
    length: { minimum: 9, maximum: 9, message: "SSN must be 9 digits" },
    numericality: true,
    allow_blank: true

  validates :encrypted_ssn, uniqueness: true, allow_blank: true

  validate :is_ssn_composition_correct?

  validates :gender,
    allow_blank: true,
    inclusion: { in: Person::GENDER_KINDS, message: "%{value} is not a valid gender" }

  before_save :generate_hbx_id
  before_save :update_full_name
  before_save :strip_empty_fields

  after_validation :move_encrypted_ssn_errors

  after_create :create_inbox

  scope :by_hbx_id, ->(person_hbx_id) { where(hbx_id: person_hbx_id) }
  scope :general_agency_staff_certified,     -> { where("general_agency_staff_roles.aasm_state" => { "$eq" => :active })}
  scope :broker_role_certified,     -> { where("broker_role.aasm_state" => { "$in" => [:active]})}

  def move_encrypted_ssn_errors
    deleted_messages = errors.delete(:encrypted_ssn)
    if !deleted_messages.blank?
      deleted_messages.each do |dm|
        errors.add(:ssn, dm)
      end
    end
    true
  end

  def has_active_consumer_role?
    consumer_role.present? and consumer_role.is_active?
  end

  def has_active_employee_role?
    active_employee_roles.any?
  end

  def active_employee_roles
    employee_roles.select{|employee_role| employee_role.census_employee && employee_role.census_employee.is_active? }
  end

  def is_active?
    is_active
  end

  def has_multiple_active_employers?
    active_employee_roles.count > 1
  end

  def mailing_address
    addresses.detect { |adr| adr.kind == "mailing" } || home_address
  end

  def home_address
    addresses.detect { |adr| adr.kind == "home" }
  end

  def generate_hbx_id
    write_attribute(:hbx_id, HbxIdGenerator.generate_member_id) if hbx_id.blank?
  end

  def strip_empty_fields
    if encrypted_ssn.blank?
      unset_sparse("encrypted_ssn")
    end
    if user_id.blank?
      unset_sparse("user_id")
    end
  end

  def unset_sparse(field)
    normalized = database_field_name(field)
    attributes.delete(normalized)
  end

  def self.encrypt_ssn(val)
    if val.blank?
      return nil
    end
    ssn_val = val.to_s.gsub(/\D/, '')
    SymmetricEncryption.encrypt(ssn_val)
  end

  def active_general_agency_staff_roles
    general_agency_staff_roles.where(:aasm_state => :active)
  end

  def has_active_employer_staff_role?
    employer_staff_roles.present? and employer_staff_roles.active.present?
  end

  def active_employer_staff_roles
    employer_staff_roles.present? ? employer_staff_roles.active : []
  end

  def active_broker_staff_roles
    broker_agency_staff_roles.where(:aasm_state => :active)
  end

  def has_active_broker_staff_role?
    !active_broker_staff_roles.empty?
  end

  def self.decrypt_ssn(val)
    SymmetricEncryption.decrypt(val)
  end

  def general_agency_primary_staff
    general_agency_staff_roles.present? ? general_agency_staff_roles.where(is_primary: true).first : nil
  end

  # Strip non-numeric chars from ssn
  # SSN validation rules, see: http://www.ssa.gov/employer/randomizationfaqs.html#a0=12
  def ssn=(new_ssn)
    if !new_ssn.blank?
      write_attribute(:encrypted_ssn, Person.encrypt_ssn(new_ssn))
    else
      unset_sparse("encrypted_ssn")
    end
  end

  def ssn
    ssn_val = read_attribute(:encrypted_ssn)
    if !ssn_val.blank?
      Person.decrypt_ssn(ssn_val)
    else
      nil
    end
  end

  def gender=(new_gender)
    write_attribute(:gender, new_gender.to_s.downcase)
  end

  def primary_family
    @primary_family ||= Family.find_primary_applicant_by_person(self).first
  end

  def update_full_name
    full_name
  end

  def full_name
    @full_name = [name_pfx, first_name, middle_name, last_name, name_sfx].compact.join(" ")
  end

  def add_work_email(email)
    existing_email = self.emails.detect do |e|
      (e.kind == 'work') &&
        (e.address.downcase == email.downcase)
    end
    return nil if existing_email.present?
    self.emails << ::Email.new(:kind => 'work', :address => email)
  end

  def work_email_or_best
    email = emails.detect { |adr| adr.kind == "work" } || emails.first
    (email && email.address) || (user && user.email)
  end

  def work_phone
    phones.detect { |phone| phone.kind == "work" } || main_phone
  end

  def main_phone
    phones.detect { |phone| phone.kind == "main" }
  end

  def home_phone
    phones.detect { |phone| phone.kind == "home" }
  end

  def mobile_phone
    phones.detect { |phone| phone.kind == "mobile" }
  end


  def work_phone_or_best
    best_phone  = work_phone || mobile_phone || home_phone
    best_phone ? best_phone.full_phone_number : nil
  end


  class << self

    def additional_exprs(clean_str)
      additional_exprs = []
      if clean_str.include?(" ")
        parts = clean_str.split(" ").compact
        first_re = ::Regexp.new(::Regexp.escape(parts.first), true)
        last_re = ::Regexp.new(::Regexp.escape(parts.last), true)
        additional_exprs << {:first_name => first_re, :last_name => last_re}
      end
      additional_exprs
    end

    def search_first_name_last_name_npn(s_str, query=self)
      clean_str = s_str.strip
      s_rex = ::Regexp.new(::Regexp.escape(s_str.strip), true)
      query.where({
        "$or" => ([
          {"first_name" => s_rex},
          {"last_name" => s_rex},
          {"broker_role.npn" => s_rex}
          ] + additional_exprs(clean_str))
        })
    end

    def brokers_matching_search_criteria(search_str)
      broker_role_certified.search_first_name_last_name_npn(search_str)
    end

    def agencies_with_matching_broker(search_str)
      if brokers_matching_search_criteria(search_str).exists(:"broker_role.benefit_sponsors_broker_agency_profile_id" => true)
        brokers_matching_search_criteria(search_str).map(&:broker_role).map(&:benefit_sponsors_broker_agency_profile_id)
      else
        brokers_matching_search_criteria(search_str).map(&:broker_role).map(&:broker_agency_profile_id)
      end
    end

    def general_agencies_matching_search_criteria(search_str)
      general_agency_staff_certified.search_first_name_last_name_npn(search_str)
    end

    def match_existing_person(personish)
      return nil if personish.ssn.blank?
      Person.where(:encrypted_ssn => encrypt_ssn(personish.ssn), :dob => personish.dob).first
    end

    def find_by_ssn(ssn)
      Person.where(encrypted_ssn: Person.encrypt_ssn(ssn)).first
    end

    # Return an instance list of active People who match identifying information criteria
    def match_by_id_info(options)
      ssn_query = options[:ssn]
      dob_query = options[:dob]
      last_name = options[:last_name]
      first_name = options[:first_name]

      raise ArgumentError, "must provide an ssn or first_name/last_name/dob or both" if (ssn_query.blank? && (dob_query.blank? || last_name.blank? || first_name.blank?))

      matches = Array.new
      matches.concat Person.active.where(encrypted_ssn: encrypt_ssn(ssn_query), dob: dob_query).to_a unless ssn_query.blank?
      #matches.concat Person.where(last_name: last_name, dob: dob_query).active.to_a unless (dob_query.blank? || last_name.blank?)
      if first_name.present? && last_name.present? && dob_query.present?
        first_exp = /^#{first_name}$/i
        last_exp = /^#{last_name}$/i
        matches.concat Person.active.where(dob: dob_query, last_name: last_exp, first_name: first_exp).to_a.select{|person| person.ssn.blank? || ssn_query.blank?}
      end
      matches.uniq
    end

    def staff_for_employer(employer_profile)
      self.where(:employer_staff_roles => {
                     '$elemMatch' => {
                         benefit_sponsor_employer_profile_id: employer_profile.id,
                         aasm_state: :is_active}
                 }).to_a
    end

    def staff_for_broker(broker_profile)
      Person.where(:broker_agency_staff_roles =>
                     {
                       '$elemMatch' =>
                         {
                           aasm_state: :active,
                           '$or' => [
                             {benefit_sponsors_broker_agency_profile_id: broker_profile.id},
                             {broker_agency_profile_id: broker_profile.id}
                           ]
                         }
                     })
    end

    def staff_for_ga(general_agency_profile)
      Person.where(:general_agency_staff_roles =>
                     {
                       '$elemMatch' =>
                         {
                           aasm_state: :active,
                           '$or' => [
                             {benefit_sponsors_general_agency_profile_id: general_agency_profile.id},
                             {general_agency_profile_id: general_agency_profile.id}
                           ]
                         }
                     })
    end

    def staff_for_ga_including_pending(general_agency_profile)
      Person.where(:general_agency_staff_roles =>
                     {
                       '$elemMatch' => {
                         '$and' => [
                           {
                             '$or' => [
                               {benefit_sponsors_general_agency_profile_id: general_agency_profile.id}
                             ]
                           },
                           {
                             '$or' => [
                               {aasm_state: :general_agency_pending},
                               {aasm_state: :active}
                             ]
                           }
                         ]
                       }
                     })
    end

    def staff_for_employer_including_pending(employer_profile)
      self.where(:employer_staff_roles => {
                     '$elemMatch' => {
                         benefit_sponsor_employer_profile_id: employer_profile.id,
                         :aasm_state.ne => :is_closed
                     }
                 })
    end

    def staff_for_broker_including_pending(broker_profile)
      Person.where(:broker_agency_staff_roles =>
                     {
                       '$elemMatch' => {
                         '$and' => [
                           {
                             '$or' => [
                               {benefit_sponsors_broker_agency_profile_id: broker_profile.id}
                             ]
                           },
                           {
                             '$or' => [
                               {aasm_state: :broker_agency_pending},
                               {aasm_state: :active}
                             ]
                           }
                         ]
                       }
                     })
    end

    # Adds employer staff role to person
    # Returns status and message if failed
    # Returns status and person if successful
    def add_employer_staff_role(first_name, last_name, dob, email, employer_profile)
      person = Person.where(first_name: /^#{first_name}$/i, last_name: /^#{last_name}$/i, dob: dob)

      return false, 'Person count too high, please contact HBX Admin' if person.count > 1
      return false, 'Person does not exist on the HBX Exchange' if person.count == 0

      employer_staff_role = EmployerStaffRole.create(person: person.first, benefit_sponsor_employer_profile_id: employer_profile._id)
      employer_staff_role.save
      return true, person.first
    end

    # Sets employer staff role to inactive
    # Returns false if person not found
    # Returns false if employer staff role not matches
    # Returns true is role was marked inactive
    def deactivate_employer_staff_role(person_id, employer_profile_id)
      begin
        person = Person.find(person_id)
      rescue
        return false, 'Person not found'
      end
      if role = person.employer_staff_roles.detect{|role| role.benefit_sponsor_employer_profile_id.to_s == employer_profile_id.to_s && !role.is_closed?}
        role.update_attributes!(:aasm_state => :is_closed)
        return true, 'Employee Staff Role is inactive'
      else
        return false, 'No matching employer staff role'
      end
    end
  end

  def agent?
    agent = self.csr_role || self.assister_role || self.broker_role || self.hbx_staff_role || self.general_agency_staff_roles.present?
    !!agent
  end

  def contact_info(email_address, area_code, number, extension)
    if email_address.present?
      email = emails.detect{|mail|mail.kind == 'work'}
      if email
        email.update_attributes!(address: email_address)
      else
        email= Email.new(kind: 'work', address: email_address)
        emails.append(email)
        self.update_attributes!(emails: emails)
        save!
      end
    end
    phone = phones.detect{|p|p.kind == 'work'}
    if phone
      phone.update_attributes!(area_code: area_code, number: number, extension: extension)
    else
      phone = Phone.new(kind: 'work', area_code: area_code, number: number, extension: extension)
      phones.append(phone)
      self.update_attributes!(phones: phones)
      save!
    end
  end

  private

  def create_inbox
    welcome_subject = "Welcome to #{Settings.site.short_name}"
    if broker_role || broker_agency_staff_roles.present?
      welcome_body = "#{Settings.site.short_name} is the #{Settings.aca.state_name}'s on-line marketplace to shop, compare, and select health insurance that meets your health needs and budgets."
    else
      welcome_body = "#{Settings.site.site_short_name} is ready to help you get quality, affordable medical or dental coverage that meets your needs and budget.<br/><br/>Now that you’ve created an account, take a moment to explore your account features. Remember there’s limited time to sign up for a plan. Make sure you pay attention to deadlines.<br/><br/>If you have any questions or concerns, we’re here to help.<br/><br/>#{Settings.site.site_short_name}<br/>#{Settings.contact_center.short_number}<br/>TTY: #{Settings.contact_center.tty_number}"
    end
    mailbox = Inbox.create(recipient: self)
    mailbox.messages.create(subject: welcome_subject, body: welcome_body, from: "#{Settings.site.short_name}")
  end

  def is_ssn_composition_correct?
    # Invalid compositions:
    #   All zeros or 000, 666, 900-999 in the area numbers (first three digits);
    #   00 in the group number (fourth and fifth digit); or
    #   0000 in the serial number (last four digits)

    if ssn.present?
      invalid_area_numbers = %w(000 666)
      invalid_area_range = 900..999
      invalid_group_numbers = %w(00)
      invalid_serial_numbers = %w(0000)

      return false if ssn.to_s.blank?
      return false if invalid_area_numbers.include?(ssn.to_s[0,3])
      return false if invalid_area_range.include?(ssn.to_s[0,3].to_i)
      return false if invalid_group_numbers.include?(ssn.to_s[3,2])
      return false if invalid_serial_numbers.include?(ssn.to_s[5,4])
    end

    true
  end

  def no_changing_my_user
    if self.persisted? && self.user_id_changed?
      old_user, new_user= self.user_id_change
      return if old_user.blank?
      if (old_user != new_user)
        errors.add(:base, "you may not change the user_id of a person once it has been set and saved")
      end
    end
  end

  # Verify basic date rules
  def date_functional_validations
    date_of_birth_is_past
    date_of_death_is_blank_or_past
    date_of_death_follows_date_of_birth
  end

  def date_of_death_is_blank_or_past
    return unless self.date_of_death.present?
    errors.add(:date_of_death, "future date: #{self.date_of_death} is invalid date of death") if TimeKeeper.date_of_record < self.date_of_death
  end

  def date_of_birth_is_past
    return unless self.dob.present?
    errors.add(:dob, "future date: #{self.dob} is invalid date of birth") if TimeKeeper.date_of_record < self.dob
  end

  def date_of_death_follows_date_of_birth
    return unless self.date_of_death.present? && self.dob.present?

    if self.date_of_death < self.dob
      errors.add(:date_of_death, "date of death cannot preceed date of birth")
      errors.add(:dob, "date of birth cannot follow date of death")
    end
  end
end
