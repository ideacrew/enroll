class Family
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Versioning

  Kinds = %W[unassisted_qhp insurance_assisted_qhp employer_sponsored streamlined_medicaid emergency_medicaid hcr_chip]
  ImmediateFamily = %w{self spouse life_partner child ward foster_child adopted_child stepson_or_stepdaughter}

  auto_increment :hbx_assigned_id, seed: 9999

  field :e_case_id, type: String # Eligibility system foreign key
  field :e_status_code, type: String
  field :application_type, type: String
  field :renewal_consent_through_year, type: Integer # Authorize auto-renewal elibility check through this year (CCYY format)

  field :is_active, type: Boolean, default: true # ApplicationGroup active on the Exchange?
  field :submitted_at, type: DateTime # Date application was created on authority system
  field :updated_by, type: String

  # All current and former members of this group
  belongs_to  :person
  embeds_many :family_members, cascade_callbacks: true
  embeds_many :special_enrollment_periods, cascade_callbacks: true
  embeds_many :irs_groups, cascade_callbacks: true
  embeds_many :households, cascade_callbacks: true, :before_add => :reset_active_household

  accepts_nested_attributes_for :special_enrollment_periods, :family_members, :irs_groups, :households

  index({person_id: 1})
  index({e_case_id: 1}, { unique: true, sparse: true })
  index({is_active: 1})
  index({submitted_at: 1})

  # child model indexes
  index({"family_member._id" => 1}, { unique: true, sparse: true })
  index({"family_member.person_id" => 1})
  index({"family_member.broker_role_id" => 1})
  index({"family_member.is_primary_applicant" => 1})
  index({"family_member.hbx_enrollment_exemption.certificate_number" => 1})
  index({"household.hbx_enrollment.broker_agency_id" => 1}, {sparse: true})
  index({"household.hbx_enrollment.policy_id" => 1}, { unique: true, sparse: true })
  index({"household.tax_household.hbx_assigned_id" => 1})
  index({"household.tax_household.tax_household_member.financial_statement.submitted_date" => 1})
  index({"irs_group.hbx_assigned_id" => 1})

  validates :renewal_consent_through_year,
            numericality: {only_integer: true, inclusion: 2014..2025},
            :allow_nil => true

  validates :e_case_id, uniqueness: true, allow_nil: true

  validate :no_duplicate_family_members
  validate :integrity_of_family_member_objects
  validate :max_one_primary_applicant
  validate :max_one_active_household

  before_save :update_household

  scope :all_with_multiple_family_members, -> { exists({:'family_members.1' => true}) }
  scope :all_with_household, -> { exists({:'households.0' => true}) }

  def latest_household
    return households.first if households.size == 1
    households.order_by(:'submitted_at'.desc).limit(1).only(:households).first
    # persisted_household = households.select(&:persisted?) - [nil] #remove any nils
    # persisted_household.sort_by(&:submitted_at).last
  end

  def active_family_members
    family_members.find_all { |a| a.is_active? }
  end

  # Life events trigger special enrollment periods
  def is_under_special_enrollment_period?
    return false if special_enrollment_periods.size == 0
    sep = special_enrollment_periods.order_by(:begin_on.desc).limit(1).only(:special_enrollment_periods).first
    sep.is_active?
  end

  def current_special_enrollment_periods
    return [] if special_enrollment_periods.size == 0
    seps = special_enrollment_periods.order_by(:begin_on.desc).only(:special_enrollment_periods)
    seps.reduce([]) { |list, event| list << event if event.is_active?; list }
  end

  # single SEP with latest end date from list of active SEPs
  def current_sep
    active_seps.max { |sep| sep.end_date }
  end

  # List of SEPs active for this Application Group today, or passed date
  def active_seps(day = Date.today)
    special_enrollment_periods.find_all { |sep| (sep.start_date..sep.end_date).include?(day) }
  end

  def active_broker_roles
    active_household.hbx_enrollments.reduce([]) { |b, e| b << e.broker_role if e.is_active? && !e.broker_role.blank? } || []
  end

  def primary_applicant
    family_members.detect { |a| a.is_primary_applicant? }
  end

  def consent_applicant
    family_members.detect { |a| a.is_consent_applicant? }
  end

  def add_family_member(new_person)

  end

  def remove_family_member(person)
  end

  def find_family_member_by_person(person)
    family_members.detect { |a| a.person_id == person._id }
  end

  def person_is_family_member?(person)
    return true unless find_family_member_by_person(person).blank?
  end

  def active_household
    households.detect do |household|
      household.is_active?
    end
  end

  def dependents
    family_members.reject(&:is_primary_applicant)
  end

  def people_relationship_map
    map = Hash.new
    people.each do |person|
      map[person] = person_relationships.detect { |r| r.object_person == person.id }.relationship_kind
    end
    map
  end

  def is_active?
    self.is_active
  end

  def initialize_from_employee_role(new_employee_role)
    set_family_attributes
    initialize_irs_group
    initialize_household
    initialize_family_members_and_coverage_households(new_employee_role.person)
  end

  class << self
    def default_search_order
      [
          ["primary_applicant.name_last", 1],
          ["primary_applicant.name_first", 1]
      ]
    end

    def find_or_initialize_by_employee_role(new_employee_role)
      existing_family = Family.find_by_employee_role(new_employee_role)

      if existing_family.present?
        existing_family
      else
        family = Family.new
        family.initialize_from_employee_role(new_employee_role)

        family.save!
        family
      end
    end

    # TODO: should probably go away assuming 1 person should only have 1 family with them as primary
    def find_all_by_primary_applicant(person)
      Family.find_all_by_person(person).select() { |f| f.primary_applicant.person.id.to_s == person.id.to_s }
    end

    def find_by_primary_family_member(person)
      find_all_by_primary_applicant(person).first
    end

    def find_by_employee_role(employee_role)
      find_all_by_primary_applicant(employee_role.person).first
    end

    def find_by_primary_applicant(person)
      find_all_by_primary_applicant(person).first
    end

    def find_all_by_person(person)
      Family.where("family_members.person_id" => person.id)
    end

    def find_family_member(family_member_id)
      family = Family.where("family_members._id" => family_member_id).first
      family.family_members.detect { |member| member._id == family_member_id }
    end

    def find_by_case_id(case_id)
      where({"e_case_id" => case_id}).first
    end
  end

private
  def set_family_attributes
    self.submitted_at = DateTime.current
  end

  def initialize_irs_group
    irs_groups.build(effective_starting_on: Date.current)
  end

  def initialize_household
    households.build(irs_group: irs_groups.first, effective_starting_on: irs_groups.first.effective_starting_on, submitted_at: DateTime.current)
  end

  def initialize_family_members_and_coverage_households(primary_person)
    time_stamp = DateTime.current
    primary_coverage_household = households.first.coverage_households.build(is_immediate_family: true, submitted_at: time_stamp)

    family_member = family_members.build(person: primary_person, is_primary_applicant: true)
    primary_coverage_household.coverage_household_members.build(family_member: family_member, is_subscriber: true)

    primary_person.person_relationships.each do |kin|
      family_member = family_members.build(person: kin.relative)

      if ImmediateFamily.include? kin.kind.to_s.downcase
        primary_coverage_household.coverage_household_members.build(family_member: family_member)
      else
        secondary_coverage_household ||= households.first.coverage_households.build(is_immediate_family: false, submitted_at: time_stamp)
        secondary_coverage_household.coverage_household_members.build(family_member: family_member)
      end
    end 
  end 

  def update_household
    household = get_household

    if family_members.blank?
      household.coverage_households.delete_all
    else
      create_coverage_households(household)
    end
  end

  def no_duplicate_family_members
    family_members.group_by { |appl| appl.person_id }.select { |k, v| v.size > 1 }.each_pair do |k, v|
      errors.add(:base, "Duplicate family_members for person: #{k}\n" +
                          "family_members: #{v.inspect}")
    end
  end

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

  def get_household
    if active_household
     active_household  #if active_houshold exists
    else
     initialize_irs_group
     initialize_household 
     # households.build(submitted_at: DateTime.current) #create a new empty household
    end
  end

  def create_coverage_households(household)
    time_stamp ||= DateTime.current
    household.coverage_households.delete_all #clear any existing

    coverage_household = household.coverage_households.build(submitted_at: self.submitted_at)
    coverage_household_for_others = nil

    family_members.each do |family_member|
      if family_member.is_coverage_applicant?
        if valid_relationship?(family_member)
          coverage_household_member = coverage_household.coverage_household_members.build
          coverage_household_member.family_member = family_member
          coverage_household_member.applicant_id = family_member.person_id
          coverage_household_member.is_subscriber = family_member.is_primary_applicant
        else
          coverage_household_for_others ||= household.coverage_households.build({submitted_at: self.submitted_at})
          coverage_household_member = coverage_household_for_others.coverage_household_members.build
          coverage_household_member.family_member = family_member
        end
      end
    end
  end

  def valid_relationship?(family_member)
    return true if primary_applicant.nil? #responsible party case
    return true if primary_applicant.person.id == family_member.person.id

    if ImmediateFamily.include? primary_applicant.person.find_relationship_with(family_member.person)
      return true
    else
      return false
    end
  end
end
