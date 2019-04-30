class Household
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps
  include HasFamilyMembers

  ImmediateFamily = %w{self spouse life_partner child ward foster_child adopted_child stepson_or_stepdaughter stepchild domestic_partner}

  embedded_in :family

  field :irs_group_id, type: BSON::ObjectId
  field :effective_starting_on, type: Date
  field :effective_ending_on, type: Date
  field :submitted_at, type: DateTime
  field :is_active, type: Boolean, default: true

  embeds_many :hbx_enrollments
  embeds_many :coverage_households, cascade_callbacks: true

  accepts_nested_attributes_for :hbx_enrollments, :coverage_households
  
  before_validation :set_effective_starting_on
  before_validation :set_effective_ending_on #, :if => lambda {|household| household.effective_ending_on.blank? } # set_effective_starting_on should be done before this
  before_validation :reset_is_active_for_previous
  before_validation :set_submitted_at #, :if => lambda {|household| household.submitted_at.blank? }

  validates :effective_starting_on, presence: true

  def active_hbx_enrollments
    actives = hbx_enrollments.collect() do |list, enrollment|
      if enrollment.plan.present? &&
         (enrollment.plan.active_year >= TimeKeeper.date_of_record.year) &&
         (HbxEnrollment::ENROLLED_STATUSES.include?(enrollment.aasm_state))

        list << enrollment
      end
      list
    end
    actives.sort! { |a,b| a.submitted_at <=> b.submitted_at }
  end

  def renewing_hbx_enrollments
    active_hbx_enrollments.reject { |en| !HbxEnrollment::RENEWAL_STATUSES.include?(enrollment.aasm_state) }
  end

  def renewing_individual_market_hbx_enrollments
    renewing_hbx_enrollments.reject { |en| en.enrollment_kind != 'individual' }
  end

  def add_household_coverage_member(family_member)
    if Family::IMMEDIATE_FAMILY.include?(family_member.primary_relationship)
      immediate_family_coverage_household.add_coverage_household_member(family_member)
      extended_family_coverage_household.remove_family_member(family_member)
    else
      immediate_family_coverage_household.remove_family_member(family_member)
      extended_family_coverage_household.add_coverage_household_member(family_member)
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
    return coverage_households.first if coverage_households.size == 1
    coverage_households.sort_by(&:submitted_at).last.submitted_at
  end

  def applicant_ids
    ch_applicant_ids = coverage_households.inject([]) do |acc, ch|
      acc + ch.applicant_ids
    end
    hbxe_applicant_ids = hbx_enrollments.inject([]) do |acc, he|
      acc + he.applicant_ids
    end
    (ch_applicant_ids + hbxe_applicant_ids).distinct
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

  def set_effective_starting_on
    return true unless self.effective_starting_on.blank?

    self.effective_starting_on =  parent.submitted_at
    true
  end

  def set_submitted_at
    return true unless self.submitted_at.blank?

    self.submitted_at = parent.submitted_at unless self.submitted_at
    true
  end

  def new_hbx_enrollment_from(employee_role: nil, coverage_household: nil, benefit_group: nil, benefit_group_assignment: nil, resident_role: nil, consumer_role: nil, benefit_package: nil, qle: false, submitted_at: nil, coverage_start: nil, enrollment_kind:nil, external_enrollment: false, opt_effective_on: nil)
    coverage_household = latest_coverage_household unless coverage_household.present?
    HbxEnrollment.new_from(
      employee_role: employee_role,
      resident_role: resident_role,
      coverage_household: coverage_household,
      benefit_group: benefit_group,
      benefit_group_assignment: benefit_group_assignment,
      consumer_role: consumer_role,
      benefit_package: benefit_package,
      qle: qle,
      submitted_at: Time.now,
      external_enrollment: external_enrollment,
      coverage_start: coverage_start,
      opt_effective_on: opt_effective_on
    )
  end

  def create_hbx_enrollment_from(employee_role: nil, coverage_household: nil, benefit_group: nil, benefit_group_assignment: nil, consumer_role: nil, benefit_package: nil, submitted_at: nil)
    enrollment = new_hbx_enrollment_from(
      employee_role: employee_role,
      coverage_household: coverage_household,
      benefit_group: benefit_group,
      benefit_group_assignment: benefit_group_assignment,
      consumer_role: consumer_role,
      benefit_package: benefit_package,
      submitted_at: Time.now
    )
    enrollment.save
    enrollment
  end

  def delete_hbx_enrollment(hbx_enrollment_id)
    hbx_enrollment = hbx_enrollments.detect {hbx_enrollment_id}
    if hbx_enrollment.present?
      benefit_group_assignment = hbx_enrollment.benefit_group_assignment

      if benefit_group_assignment.present?
        benefit_group_assignment.destroy! && hbx_enrollment.destroy!
      else
        hbx_enrollment.destroy!
      end
    else
      return false
    end
  end

  def remove_family_member(member)
    coverage_households.each do |c_household|
      c_household.remove_family_member(member)
    end
  end

  def enrolled_including_waived_hbx_enrollments
    #hbx_enrollments.coverage_selected_and_waived
    enrs = hbx_enrollments.coverage_selected_and_waived
    health_enr = enrs.detect { |a| a.coverage_kind == "health"}
    dental_enr = enrs.detect { |a| a.coverage_kind == "dental"}
    [health_enr , dental_enr].compact
  end

  def enrolled_hbx_enrollments
    hbx_enrollments.enrolled
  end
end
