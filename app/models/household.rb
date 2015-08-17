class Household
  include Mongoid::Document
  include Mongoid::Timestamps
  include HasFamilyMembers

  ImmediateFamily = %w{self spouse life_partner child ward foster_child adopted_child stepson_or_stepdaughter}

  embedded_in :family

  # field :e_pdc_id, type: String  # Eligibility system PDC foreign key

  # embedded belongs_to :irs_group association
  field :irs_group_id, type: BSON::ObjectId
  field :effective_starting_on, type: Date
  field :effective_ending_on, type: Date
  field :submitted_at, type: DateTime
  field :is_active, type: Boolean, default: true

  embeds_many :hbx_enrollments
  embeds_many :tax_households
  embeds_many :coverage_households, cascade_callbacks: true

  accepts_nested_attributes_for :hbx_enrollments, :tax_households, :coverage_households

  before_validation :set_effective_starting_on
  before_validation :set_effective_ending_on #, :if => lambda {|household| household.effective_ending_on.blank? } # set_effective_starting_on should be done before this
  before_validation :reset_is_active_for_previous
  before_validation :set_submitted_at #, :if => lambda {|household| household.submitted_at.blank? }

  validates :effective_starting_on, presence: true
  #validate :effective_ending_on_gt_effective_starting_on

  # after_build :build_irs_group


  def add_household_coverage_member(family_member)
    # OPTIMIZE
    if ImmediateFamily.include?(family_member.primary_relationship)
      immediate_family_coverage_household.coverage_household_members.build(
          family_member: family_member,
          is_subscriber: family_member.is_primary_applicant?
        )
    else
      extended_family_coverage_household.coverage_household_members.build(
          family_member: family_member,
          is_subscriber: family_member.is_primary_applicant?
        )
    end
  end

  def immediate_family_coverage_household
    ch = coverage_households.detect { |hh| hh.is_immediate_family? }
    ch ||= coverage_households.build(is_immediate_family: true)
  end

  def extended_family_coverage_household
    ch = coverage_households.detect { |hh| !hh.is_immediate_family? }
    ch ||= coverage_households.build(is_immediate_family: false)
  end

  # def determination_split_coverage_household
  #   hh = coverage_household.find_or_initialize_by(is_determination_split_household: true)
  #   hh.submitted_at ||= DateTime.current
  #   hh
  # end

  def effective_ending_on_gt_effective_starting_on

    return if effective_ending_on.nil?
    return if effective_starting_on.nil?

      if effective_ending_on < effective_starting_on
        self.errors.add(:base, "The effective end date should be earlier or equal to effective start date")
      end
  end

  def parent
    raise "undefined parent family" unless self.family
    self.family
  end

  def irs_group=(new_irs_group)
    return unless new_irs_group.is_a? IrsGroup
    self.irs_group_id = new_irs_group._id
    @irs_group = new_irs_group
  end

  def irs_group
    return @irs_group if defined? @irs_group
    @irs_group = parent.irs_groups.find(self.irs_group_id)
  end

  def is_active?
    self.is_active
  end

  def latest_coverage_household
    return coverage_households.first if coverage_households.size = 1
    coverage_households.sort_by(&:submitted_at).last.submitted_at
  end

  def applicant_ids
    th_applicant_ids = tax_households.inject([]) do |acc, th|
      acc + th.applicant_ids
    end
    ch_applicant_ids = coverage_households.inject([]) do |acc, ch|
      acc + ch.applicant_ids
    end
    hbxe_applicant_ids = hbx_enrollments.inject([]) do |acc, he|
      acc + he.applicant_ids
    end
    (th_applicant_ids + ch_applicant_ids + hbxe_applicant_ids).distinct
  end

  # This will set the effective_ending_on of previously active household to 1 day
  # before start of the current household's effective_starting_on
  def set_effective_ending_on
    return true unless self.effective_starting_on

    latest_household = self.family.latest_household
    return true if self == latest_household

    latest_household.effective_ending_on = self.effective_starting_on - 1.day
    true
  end

  def reset_is_active_for_previous
    latest_household = self.family.latest_household
    active_value = self.is_active
    latest_household.is_active = false
    self.is_active = active_value
    true
  end

  def set_submitted_at
    return true unless self.submitted_at.blank?

    self.submitted_at = tax_households.sort_by(&:updated_at).last.updated_at if tax_households.length > 0
    self.submitted_at = parent.submitted_at unless self.submitted_at
    true
  end

  def set_effective_starting_on
    return true unless self.effective_starting_on.blank?

    self.effective_starting_on =  parent.submitted_at
    true
  end

  def new_hbx_enrollment_from(employee_role: nil, coverage_household: nil, benefit_group: nil, consumer_role: nil, benefit_package: nil)
    coverage_household = latest_coverage_household unless coverage_household.present?
    HbxEnrollment.new_from(
      employee_role: employee_role,
      coverage_household: coverage_household,
      benefit_group: benefit_group,
      consumer_role: consumer_role,
      benefit_package: benefit_package,
    )
  end

  def create_hbx_enrollment_from(employee_role: nil, coverage_household: nil, benefit_group: nil, consumer_role: nil, benefit_package: nil)
    enrollment = new_hbx_enrollment_from(
      employee_role: employee_role,
      coverage_household: coverage_household,
      benefit_group: benefit_group,
      consumer_role: consumer_role,
      benefit_package: benefit_package,
    )
    enrollment.save
    enrollment
  end

  def remove_family_member(member)
    coverage_households.each do |c_household|
      c_household.remove_family_member(member)
    end
  end
end
