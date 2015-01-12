class Family  # aka class ApplicationGroup
  include Mongoid::Document
  include Mongoid::Timestamps

  KINDS = %W[unassisted_qhp insurance_assisted_qhp employer_sponsored streamlined_medicaid emergency_medicaid hcr_chip]

  # auto_increment :hbx_assigned_id, seed: 9999

  field :e_case_id, type: String  # Eligibility system foreign key
  field :e_status_code, type: String
  field :renewal_consent_through_year, type: Integer  # Authorize auto-renewal elibility check through this year (CCYY format)

  field :is_active, type: Boolean, default: true   # ApplicationGroup active on the Exchange?
  field :submitted_at, type: DateTime            # Date application was created on authority system
  field :updated_by, type: String, default: "consumer"

  has_and_belongs_to_many :qualifying_life_events

  # All current and former members of this group
  embeds_many :family_members, cascade_callbacks: true
  accepts_nested_attributes_for :family_members

  embeds_many :households, cascade_callbacks: true
  accepts_nested_attributes_for :households

  embeds_many :irs_groups, cascade_callbacks: true
  accepts_nested_attributes_for :irs_groups

  embeds_many :comments
  accepts_nested_attributes_for :comments, reject_if: proc { |attribs| attribs['content'].blank? }, allow_destroy: true

  validates :renewal_consent_through_year,
              numericality: { only_integer: true, inclusion: 2014..2025 },
              :allow_nil => true

  validates :e_case_id, uniqueness: true

#  validates_inclusion_of :max_renewal_year, :in => 2013..2025, message: "must fall between 2013 and 2030"

  index({e_case_id:  1})
  index({is_active:  1})
  index({aasm_state:  1})
  index({submitted_date:  1})

  # FamilyMember child model indexes
  index({"family_member.person_id" => 1})
  index({"family_member.broker_id" =>  1})
  index({"family_member.is_primary_applicant" => 1})

  # HbxEnrollment child model indexes
  index({"hbx_enrollment.policy_id" => 1})

  validate :no_duplicate_family_members

  scope :all_with_single_family_member, ->{ exists({ :'family_members.1' => false })}
  scope :all_with_multiple_family_members, ->{ exists({ :'family_members.1' => true })}

  def no_duplicate_family_members
    family_members.group_by { |appl| appl.person_id }.select { |k, v| v.size > 1 }.each_pair do |k, v|
      errors.add(:base, "Duplicate family_members for person: #{k}\n" +
                         "family_members: #{v.inspect}")
    end
  end

  def latest_household
    return households.first if households.size = 1
    households.sort_by(&:submitted_at).last.submitted_at
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
    hbx_enrollments.inject([]) { |b, e| b << e.broker unless e.broker.blank? } || []
  end

  def active_brokers
    hbx_enrollments.inject([]) { |b, e| b << e.broker if e.is_active? && !e.broker.blank? } || []
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

private

  def validate_one_and_only_one_primary_family_member
    # family_members.detect { |a| a.is_primary_applicant? }
  end

end
