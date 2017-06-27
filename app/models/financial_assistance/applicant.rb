class FinancialAssistance::Applicant
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :application

  TAX_FILER_KINDS = %W(tax_filer single joint separate dependent non_filer)
  STUDENT_KINDS = %w(
    dropped_out
    elementary
    english_language_institute
    full_time
    ged
    graduated
    graduate_school
    half_time
    junior_school
    not_in_school
    open_university
    part_time
    preschool
    primary
    secondary
    technical
    undergraduate
    vocational
    vocational_tech
  )

  STUDENT_SCHOOL_KINDS = %w(
    english_language_institute
    elementary
    equivalent_vocational_tech
    graduate_school
    ged
    high_school
    junior_school
    open_university
    pre_school
    primary
    technical
    undergraduate
    vocational
  )
  field :family_member_id, type: BSON::ObjectId
  field :tax_household_id, type: BSON::ObjectId

  field :has_fixed_address, type: Boolean, default: true
  field :is_living_in_state, type: Boolean, default: true
  field :is_temp_out_of_state, type: Boolean, default: false
  field :has_insurance, type: Boolean # not eligible and not enrolled in any other Health Coverage / Benefits

  field :is_required_to_file_taxes, type: Boolean, default: true
  field :tax_filer_kind, type: String, default: "tax_filer"
  field :is_joint_tax_filing, type: Boolean, default: false
  field :is_claimed_as_tax_dependent, type: Boolean
  field :claimed_as_tax_dependent_by, type: BSON::ObjectId

  field :is_ia_eligible, type: Boolean, default: false
  field :is_medicaid_chip_eligible, type: Boolean, default: false
  field :is_non_magi_medicaid_eligible, type: Boolean, default: false
  field :is_totally_ineligible, type: Boolean, default: false
  field :is_without_assistance, type: Boolean, default: false

  # We may not need the following two fields
  field :is_magi_medicaid, type: Boolean, default: false
  field :is_medicare_eligible, type: Boolean, default: false

  field :is_student, type: Boolean#, default: false
  field :student_kind, type: String
  field :student_school_kind, type: String
  field :student_status_end_on, type: String

  #split this out : change XSD too.
  #field :is_self_attested_blind_or_disabled, type: Boolean, default: false
  field :is_self_attested_blind, type: Boolean#, default: false
  field :is_self_attested_disabled, type: Boolean, default: false

  field :is_self_attested_long_term_care, type: Boolean, default: false

  field :is_veteran, type: Boolean, default: false
  field :is_refugee, type: Boolean, default: false
  field :is_trafficking_victim, type: Boolean, default: false

  field :is_former_foster_care, type: Boolean#, default: false
  field :age_left_foster_care, type: Integer, default: 0
  field :foster_care_us_state, type: String
  field :had_medicaid_during_foster_care, type: Boolean, default: false

  field :is_pregnant, type: Boolean#, default: false
  field :is_enrolled_on_medicaid, type: Boolean, default: false
  field :is_post_partum_period, type: Boolean, default: false
  field :children_expected_count, type: Integer, default: 0
  field :pregnancy_due_on, type: Date
  field :pregnancy_end_on, type: Date

  field :is_subject_to_five_year_bar, type: Boolean, default: false
  field :is_five_year_bar_met, type: Boolean, default: false
  field :is_forty_quarters, type: Boolean, default: false

  field :is_ssn_applied, type: Boolean
  field :non_ssn_apply_reason, type: String

  # 5 Yr. Bar QNs.
  field :moved_on_or_after_welfare_reformed_law, type: Boolean
  field :is_veteran_or_active_military, type: Boolean
  field :is_spouse_or_dep_child_of_veteran_or_active_military, type: Boolean
  field :is_currently_enrolled_in_health_plan, type: Boolean

  # Other QNs.
  field :has_daily_living_help, type: Boolean#, default: false
  field :need_help_paying_bills, type: Boolean#, default: false
  field :is_resident_post_092296, type: Boolean, default: false
  field :is_vets_spouse_or_child, type: Boolean, default: false

  field :workflow, type: Hash, default: { }
  
  embeds_many :incomes,     class_name: "::FinancialAssistance::Income"
  embeds_many :deductions,  class_name: "::FinancialAssistance::Deduction"
  embeds_many :benefits,    class_name: "::FinancialAssistance::Benefit"

  accepts_nested_attributes_for :incomes, :deductions, :benefits

  validates :validate_applicant_information, presence: true, on: :submission

  # validate :strictly_boolean

  validates :tax_filer_kind,
    inclusion: { in: TAX_FILER_KINDS, message: "%{value} is not a valid tax filer kind" },
    allow_blank: true

  alias_method :is_ia_eligible?, :is_ia_eligible
  alias_method :is_medicaid_chip_eligible?, :is_medicaid_chip_eligible
  alias_method :is_medicare_eligible?, :is_medicare_eligible
  alias_method :is_joint_tax_filing?, :is_joint_tax_filing

  def is_ia_eligible?
    is_ia_eligible
  end

  def is_medicaid_chip_eligible?
    is_medicaid_chip_eligible
  end

  def is_tax_dependent?
    tax_filer_kind.present? && tax_filer_kind == "tax_dependent"
  end

  def strictly_boolean
    unless is_ia_eligible.is_a? Boolean
      self.errors.add(:base, "is_ia_eligible should be a boolean")
    end

    unless is_medicaid_chip_eligible.is_a? Boolean
      self.errors.add(:base, "is_medicaid_chip_eligible should be a boolean")
    end
  end

  #### Use Person.consumer_role values for following
  def is_us_citizen?
  end

  def is_amerasian?
  end

  def is_native_american?
  end

  def citizen_status?
  end

  def lawfully_present?
  end

  def immigration_status?
  end

  def immigration_date?
  end

  #### Collect insurance from Benefit model
  def has_insurance?
  end

  def had_prior_insurance?
  end

  def prior_insurance_end_date?
  end

  def has_state_health_benefit?
  end

  # Has access to employer-sponsored coverage that meets ACA minimum standard value and
  #   employee responsible premium amount is <= 9.5% of Household income
  def has_employer_sponsored_coverage?
  end

  def is_without_assistance?
    is_without_assistance
  end

  def is_primary_applicant?
    family_member.is_primary_applicant?
  end

  def family_member
    @family_member ||= FamilyMember.find(family_member_id)
  end

  def consumer_role
    return @consumer_role if defined?(@consumer_role)
    @consumer_role = person.consumer_role
  end

  def person
    @person ||= family_member.person
  end

  # Use income entries to determine hours worked
  def total_hours_worked_per_week
    incomes.reduce(0) { |sum_hours, income| sum_hours + income.hours_worked_per_week }
  end

  def tobacco_user
    person.is_tobacco_user || "unknown"
  end

  def family
    family_member.family
  end

  def tax_household
    return nil unless tax_household_id
    family.active_approved_application.tax_households.where(id: tax_household_id).first
  end

  def age_on_effective_date
    return @age_on_effective_date unless @age_on_effective_date.blank?
    dob = family_member.person.dob
    coverage_start_on = Forms::TimeKeeper.new.date_of_record
    return unless coverage_start_on.present?
    age = coverage_start_on.year - dob.year

    # Shave off one year if coverage starts before birthday
    if coverage_start_on.month == dob.month
      age -= 1 if coverage_start_on.day < dob.day
    else
      age -= 1 if coverage_start_on.month < dob.month
    end

    @age_on_effective_date = age
  end

  def eligibility_determinations
    return nil unless tax_household
    tax_household.eligibility_determinations
  end

  def preferred_eligibility_determination
    return nil unless tax_household
    tax_household.preferred_eligibility_determination
  end

  def applicant_validation_complete
    is_applicant_valid?
  end

private

  def validate_applicant_information
    validates_presence_of :is_ssn_applied, :has_fixed_address, :is_claimed_as_tax_dependent, :is_joint_tax_filing, :is_living_in_state, :is_temp_out_of_state, :family_member_id#, :tax_household_id
  end

  def is_applicant_valid?
    self.valid?(:submission) ? true : false
  end
end
