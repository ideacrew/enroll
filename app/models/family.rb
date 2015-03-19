class Family
  include Mongoid::Document
  include Mongoid::Timestamps
  # include Mongoid::Attributes::Dynamic
  include Mongoid::Versioning
  # include Mongoid::Paranoia
  include AASM


  KINDS = %W[unassisted_qhp insurance_assisted_qhp employer_sponsored streamlined_medicaid emergency_medicaid hcr_chip]

  auto_increment :hbx_assigned_id, seed: 9999

  field :e_case_id, type: String  # Eligibility system foreign key
  field :e_status_code, type: String
  field :application_type, type: String
  field :renewal_consent_through_year, type: Integer  # Authorize auto-renewal elibility check through this year (CCYY format)

  field :aasm_state, type: String
  field :is_active, type: Boolean, default: true   # ApplicationGroup active on the Exchange?
  field :submitted_at, type: DateTime            # Date application was created on authority system
  field :updated_by, type: String

  has_and_belongs_to_many :qualifying_life_events

  # All current and former members of this group
  embeds_many :family_members, cascade_callbacks: true
  accepts_nested_attributes_for :family_members

  embeds_many :irs_groups, cascade_callbacks: true
  accepts_nested_attributes_for :irs_groups

  embeds_many :households, cascade_callbacks: true, :before_add => :reset_active_household
  accepts_nested_attributes_for :households

  embeds_many :comments, cascade_callbacks: true
  accepts_nested_attributes_for :comments, reject_if: proc { |attribs| attribs['content'].blank? }, allow_destroy: true

  validates :renewal_consent_through_year,
              numericality: { only_integer: true, inclusion: 2014..2025 },
              :allow_nil => true

  validates :e_case_id, uniqueness: true, allow_nil: true

#  validates_inclusion_of :max_renewal_year, :in => 2013..2025, message: "must fall between 2013 and 2030"

  index({e_case_id:  1})
  index({is_active:  1})
  index({aasm_state:  1})
  index({submitted_at:  1})
  index({"hbx_enrollment.broker_agency_id" => 1}, {sparse: true})

  # child model indexes
  index({"family_member.person_id" => 1})
  index({"family_member.broker_role_id" => 1})
  index({"family_member.is_primary_applicant" => 1})
  index({"family_member.hbx_enrollment_exemption.certificate_number" => 1})
  index({"household.hbx_enrollment.policy_id" => 1})
  index({"household.tax_household.hbx_assigned_id" => 1})
  index({"household.tax_household.tax_household_member.financial_statement.submitted_date" => 1})
  index({"irs_group.hbx_assigned_id" => 1})

  validate :no_duplicate_family_members

  validate :integrity_of_family_member_objects

  validate :max_one_primary_applicant

  validate :max_one_active_household

  scope :all_with_multiple_family_members, ->{exists({ :'family_members.1' => true })}
  scope :all_with_household, ->{exists({ :'households.0' => true })}

  def no_duplicate_family_members
    family_members.group_by { |appl| appl.person_id }.select { |k, v| v.size > 1 }.each_pair do |k, v|
      errors.add(:base, "Duplicate family_members for person: #{k}\n" +
                         "family_members: #{v.inspect}")
    end
  end

  def latest_household
    return households.first if households.size == 1
    persisted_household = households.select(&:persisted?) - [nil] #remove any nils
    persisted_household.sort_by(&:submitted_at).last
  end

  def active_family_members
    family_members.find_all { |a| a.is_active? }
  end

  def employers
    hbx_enrollments.inject([]) { |em, e| p << e.employer unless e.employer.blank? } || []
  end

  def policies
    hbx_enrollments.inject([]) { |p, e| p << e.policy unless e.policy.blank? } || []
  end

  def brokers
    hbx_enrollments.inject([]) { |b, e| b << e.broker_role unless e.broker_role.blank? } || []
  end

  def active_broker_roles
    hbx_enrollments.inject([]) { |b, e| b << e.broker_role if e.is_active? && !e.broker_role.blank? } || []
  end

  def primary_applicant
    family_members.detect { |a| a.is_primary_applicant? }
  end

  def consent_applicant
    family_members.detect { |a| a.is_consent_applicant? }
  end

  def find_family_member_by_person(person)
    family_members.detect { |a| a.person_id == person._id }
  end

  def person_is_family_member?(person)
    return true unless find_family_member_by_person(person).blank?
  end

  aasm do
    state :enrollment_closed, initial: true
    state :open_enrollment_period
    state :special_enrollment_period
    state :open_and_special_enrollment_period

    event :open_enrollment do
      transitions from: :open_enrollment_period, to: :open_enrollment_period
      transitions from: :special_enrollment_period, to: :open_and_special_enrollment_period
      transitions from: :open_and_special_enrollment_period, to: :open_and_special_enrollment_period
      transitions from: :enrollment_closed, to: :open_enrollment_period
    end

    event :close_open_enrollment do
      transitions from: :open_enrollment_period, to: :enrollment_closed
      transitions from: :special_enrollment_period, to: :special_enrollment_period
      transitions from: :open_and_special_enrollment_period, to: :special_enrollment_period
      transitions from: :enrollment_closed, to: :enrollment_closed
    end

    event :open_special_enrollment do
      transitions from: :open_enrollment_period, to: :open_and_special_enrollment_period
      transitions from: :special_enrollment_period, to: :special_enrollment_period
      transitions from: :open_and_special_enrollment_period, to: :open_and_special_enrollment_period
      transitions from: :enrollment_closed, to: :special_enrollment_period
    end

    event :close_special_enrollment do
      transitions from: :open_enrollment_period, to: :open_enrollment_period
      transitions from: :special_enrollment_period, to: :enrollment_closed
      transitions from: :open_and_special_enrollment_period, to: :open_enrollment_period
      transitions from: :enrollment_closed, to: :enrollment_closed
     end
  end

  # single SEP with latest end date from list of active SEPs
  def current_sep
    active_seps.max { |sep| sep.end_date }
  end

  # List of SEPs active for this Application Group today, or passed date
  def active_seps(day = Date.today)
    special_enrollment_periods.find_all { |sep| (sep.start_date..sep.end_date).include?(day) }
  end

  def self.default_search_order
    [
      ["primary_applicant.name_last", 1],
      ["primary_applicant.name_first", 1]
    ]
  end

  def self.find_by_primary_applicant(person)
    find_all_by_primary_applicant(person).first
  end

  # TODO: should probably go away assuming 1 person should only have 1 family with them as primary
  def self.find_all_by_primary_applicant(person)
    Family.find_all_by_person(person).select() {|f|f.primary_applicant.person.id.to_s == person.id.to_s}
  end

  def self.find_all_by_person(person)
    Family.where("family_members.person_id" => person.id)
  end

  def people_relationship_map
    map = Hash.new
    people.each do |person|
      map[person] = person_relationships.detect { |r| r.object_person == person.id }.relationship_kind
    end
    map
  end

  def self.find_by_case_id(case_id)
    where({"e_case_id" => case_id}).first
  end

  def is_active?
    self.is_active
  end

  def active_household

    household = self.households.detect do |household|
      household.is_active?
    end

    return household
  end

  def find_irs_group_by_irs_group_id(irs_group_id)
    self.irs_groups.detect do |irs_group|
      irs_group.id == irs_group_id
    end
  end

private

  # This method will return true only if all the family_members in tax_household_members and coverage_household_members are present in self.family_members
  def integrity_of_family_member_objects

    return true if self.households.blank?

    family_members_in_family = self.family_members - [nil]

    tax_household_family_members_valid = are_arrays_of_family_members_same?(family_members_in_family.map(&:id), self.households.flat_map(&:tax_households).flat_map(&:tax_household_members).map(&:applicant_id))

    coverage_family_members_valid = are_arrays_of_family_members_same?(family_members_in_family.map(&:id), self.households.flat_map(&:coverage_households).flat_map(&:coverage_household_members).map(&:applicant_id))

    tax_household_family_members_valid && coverage_family_members_valid
  end

  def are_arrays_of_family_members_same?(base_set, test_set)
    base_set.uniq.sort == test_set.uniq.sort
  end

  def max_one_primary_applicant
    primary_applicants = self.family_members.select do |applicant|
      applicant.is_primary_applicant == true
    end

    if primary_applicants.size > 1
      self.errors.add(:base, "Multiple primary applicants")
      return false
    else
      return true
    end
  end

  def reset_active_household(new_household)
    households.each do |household|
      household.is_active = false
    end
    new_household.is_active = true
  end

  def max_one_active_household

    return true if self.households.blank?

    active_households = self.households.select do |household|
      household.is_active?
    end

    if active_households.size > 1
      self.errors.add(:base, "Multiple active households")
      return false
    else
      return true
    end
  end

end
