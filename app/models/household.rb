class Household
  include Mongoid::Document
  include Mongoid::Timestamps
  include HasFamilyMembers

  embedded_in :family

  before_validation :set_effective_start_date
  before_validation :set_effective_end_date #, :if => lambda {|household| household.effective_end_date.blank? } # set_effective_start_date should be done before this
  before_validation :reset_is_active_for_previous
  before_validation :set_submitted_at #, :if => lambda {|household| household.submitted_at.blank? }

  # field :e_pdc_id, type: String  # Eligibility system PDC foreign key

  # embedded belongs_to :irs_group association
  field :irs_group_id, type: BSON::ObjectId

  field :is_active, type: Boolean, default: true
  field :effective_start_date, type: Date, default: Date.new(2014,1,1)
  field :effective_end_date, type: Date

  field :submitted_at, type: DateTime

  embeds_many :hbx_enrollments
  accepts_nested_attributes_for :hbx_enrollments

  embeds_many :tax_households
  accepts_nested_attributes_for :tax_households

  embeds_many :coverage_households
  accepts_nested_attributes_for :coverage_households

  embeds_many :comments
  accepts_nested_attributes_for :comments, reject_if: proc { |attribs| attribs['content'].blank? }, allow_destroy: true

  validates :effective_start_date, presence: true

  #validate :effective_end_date_gt_effective_start_date

  def effective_end_date_gt_effective_start_date

    return if effective_end_date.nil?
    return if effective_start_date.nil?

      if effective_end_date < effective_start_date
        self.errors.add(:base, "The effective end date should be earlier or equal to effective start date")
      end
  end

  def parent
    raise "undefined parent family" unless self.family
    self.family
  end

  def irs_group=(irs_instance)
    return unless irs_instance.is_a? IrsGroup
    self.irs_group_id = irs_instance._id
  end

  def irs_group
    parent.irs_groups.find(self.irs_group_id)
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

  # This will set the effective_end_date of previously active household to 1 day
  # before start of the current household's effective_start_date
  def set_effective_end_date
    return true unless self.effective_start_date

    latest_household = self.family.latest_household
    return true if self == latest_household

    latest_household.effective_end_date = self.effective_start_date - 1.day
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

  def set_effective_start_date
    return true unless self.effective_start_date.blank?

    self.effective_start_date =  parent.submitted_at
    true
  end

  def new_hbx_enrollment_from(employer_profile: nil, coverage_household: nil, benefit_group:)
    coverage_household = latest_coverage_household unless coverage_household.present?
    HbxEnrollment.new_from(
      employer_profile: employer_profile,
      coverage_household: coverage_household,
      benefit_group: benefit_group,
    )
  end

  def create_hbx_enrollment_from(employer_profile: nil, coverage_household: nil, benefit_group:)
    enrollment = new_hbx_enrollment_from(
      employer_profile: employer_profile,
      coverage_household: coverage_household,
      benefit_group: benefit_group,
    )
    enrollment.save
    enrollment
  end
end
