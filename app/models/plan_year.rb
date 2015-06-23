class PlanYear
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM

  embedded_in :employer_profile

  # Plan Year time period
  field :start_on, type: Date
  field :end_on, type: Date

  field :open_enrollment_start_on, type: Date
  field :open_enrollment_end_on, type: Date
  # field :published, type: Boolean

  # Number of full-time employees
  field :fte_count, type: Integer, default: 0

  # Number of part-time employess
  field :pte_count, type: Integer, default: 0

  # Number of Medicare Second Payers
  field :msp_count, type: Integer, default: 0

  field :aasm_state, type: String

  embeds_many :benefit_groups, cascade_callbacks: true
  accepts_nested_attributes_for :benefit_groups, reject_if: :all_blank, allow_destroy: true

  validates_presence_of :start_on, :end_on, :open_enrollment_start_on, :open_enrollment_end_on, :message => "is invalid"

  validate :open_enrollment_date_checks

  def parent
    raise "undefined parent employer_profile" unless employer_profile?
    self.employer_profile
  end

  alias_method :effective_date=, :start_on=
  alias_method :effective_date, :start_on

  def employee_participation_percent
    if fte_count == 0
      0
    else
      employer_profile.census_employees.where(aasm_state: "employee_role_linked").try(:count) / fte_count.to_f
    end
  end

  def editable?
    !benefit_groups.any?(&:assigned?)
  end

  def open_enrollment_contains?(date)
    (open_enrollment_start_on <= date) && (date <= open_enrollment_end_on)
  end

  def coverage_period_contains?(date)
    return (start_on <= date) if (end_on.blank?)
    (start_on <= date) && (date <= end_on)
  end

  def register_employer
    employer_profile.publish_plan_year
  end

  def minimum_employer_contribution
    unless benefit_groups.size == 0
      benefit_groups.map do |benefit_group|
        benefit_group.relationship_benefits.select do |relationship_benefit|
          relationship_benefit.relationship == "employee"
        end.min_by do |relationship_benefit|
          relationship_benefit.premium_pct
        end
      end.map(&:premium_pct).first
    end
  end

  def open_to_publish?
    employer_profile.plan_years.reject{ |py| py==self }.any?(&:published?)
  end

  def is_application_valid?
    application_warnings.blank? ? true : false
  end

  # Check plan year application for regulatory compliance
  def application_warnings
    warnings = {}

    # TODO: ENFORCE NO PUBLISH
    if benefit_groups.size == 0
      warnings.merge!({benefit_groups: "at least one benefit group must be defined for plan year"})
    end

    unless employer_profile.organization.primary_office_location.address.state.to_s.downcase == HbxProfile::StateAbbreviation.to_s.downcase
      warnings.merge!({primary_office_location: "primary office must be located in #{HbxProfile::StateName}"})
    end

    # Maximum company size at time of initial registration on the HBX
    if fte_count > HbxProfile::ShopSmallMarketFteCountMaximum
      warnings.merge!({fte_count: "number of full time equivalents (FTEs) exceeds maximum allowed (#{HbxProfile::ShopSmallMarketFteCountMaximum})"})
    end

    if open_to_publish?
      warnings.merge!({publish: "You may only have one published plan year at a time"})
    end

    # Exclude Jan 1 effective date from certain checks
    unless effective_date.yday == 1
      # Employer contribution toward employee premium must meet minimum
      if benefit_groups.size > 0 && (minimum_employer_contribution < HbxProfile::ShopEmployerContributionPercentMinimum)
        warnings.merge!({minimum_employer_contribution: "employer contribution percent toward employee premium (#{minimum_employer_contribution}) is less than minimum allowed (#{HbxProfile::ShopEmployerContributionPercentMinimum})"})
      end
    end

    warnings
  end

  # All employees present on the roster with benefit groups belonging to this plan year
  def eligible_to_enroll
    benefit_group_ids = benefit_groups.collect(&:id)
    CensusEmployee.by_benefit_group_ids(benefit_group_ids)
  end

  def eligible_to_enroll_count
    eligible_to_enroll.count
  end

  # Employees who selected or waived and are not owners or direct family members of owners
  def non_business_owner_enrolled
    enrolled.non_business_owner
  end

  def non_business_owner_enrollment_count
    non_business_owner_enrolled.count
  end

  # Any employee who selected or waived coverage
  def enrolled
    eligible_to_enroll.enrolled
  end

  def total_enrolled_count
    enrolled.count
  end

  def enrollment_ratio
    # binding.pry
    if eligible_to_enroll_count == 0
      0
    else
      ((total_enrolled_count * 1.0)/ eligible_to_enroll_count)
    end
  end

  def is_enrollment_valid?
    enrollment_errors.blank? ? true : false
  end

  # Determine enrollment composition compliance with HBX-defined guards
  def enrollment_errors
    errors = {}

    # At least one employee must be enrollable.
    if eligible_to_enroll_count == 0
      errors.merge!(eligible_to_enroll_count: "at least 1 employee must be eligible to enroll")
    end

    # At least one employee who isn't an owner or family member of owner must enroll
    if non_business_owner_enrollment_count < HbxProfile::ShopEnrollmentNonOwnerParticipationMinimum
      errors.merge!(non_business_owner_enrollment_count: "at least #{HbxProfile::ShopEnrollmentNonOwnerParticipationMinimum} non-owner employee must enroll")
    end

    # January 1 effective date exemption(s)
    unless effective_date.yday == 1
      # Verify ratio for minimum number of eligible employees that must enroll is met
      if enrollment_ratio < HbxProfile::ShopEnrollmentParticipationRatioMinimum
        errors.merge!(enrollment_ratio: "number of eligible participants enrolling (#{total_enrolled_count}) is less than minimum required #{eligible_to_enroll_count * HbxProfile::ShopEnrollmentParticipationRatioMinimum}")
      end
    end

    errors
  end

  class << self
    def find(id)
      organizations = Organization.where("employer_profile.plan_years._id" => BSON::ObjectId.from_string(id))
      organizations.size > 0 ? organizations.first.employer_profile.plan_years.unscoped.detect { |py| py._id.to_s == id.to_s} : nil
    end

    def shop_enrollment_timetable(new_effective_date)
      effective_date = new_effective_date.to_date.beginning_of_month
      prior_month = effective_date - 1.month
      plan_year_start_on = effective_date
      plan_year_end_on = effective_date + 1.year - 1.day
      employer_initial_application_earliest_start_on = (effective_date - HbxProfile::ShopPlanYearPublishBeforeEffectiveDateMaximum)
      employer_initial_application_earliest_submit_on = employer_initial_application_earliest_start_on
      employer_initial_application_latest_submit_on   = ("#{prior_month.year}-#{prior_month.month}-#{HbxProfile::ShopPlanYearPublishedDueDayOfMonth}").to_date
      open_enrollment_earliest_start_on     = effective_date - HbxProfile::ShopOpenEnrollmentPeriodMaximum.months
      open_enrollment_latest_start_on       = ("#{prior_month.year}-#{prior_month.month}-#{HbxProfile::ShopOpenEnrollmentBeginDueDayOfMonth}").to_date
      open_enrollment_latest_end_on         = ("#{prior_month.year}-#{prior_month.month}-#{HbxProfile::ShopOpenEnrollmentEndDueDayOfMonth}").to_date
      binder_payment_due_date               = first_banking_date_prior ("#{prior_month.year}-#{prior_month.month}-#{HbxProfile::ShopBinderPaymentDueDayOfMonth}")


      timetable = {
        effective_date: effective_date,
        plan_year_start_on: plan_year_start_on,
        plan_year_end_on: plan_year_end_on,
        employer_initial_application_earliest_start_on: employer_initial_application_earliest_start_on,
        employer_initial_application_earliest_submit_on: employer_initial_application_earliest_submit_on,
        employer_initial_application_latest_submit_on: employer_initial_application_latest_submit_on,
        open_enrollment_earliest_start_on: open_enrollment_earliest_start_on,
        open_enrollment_latest_start_on: open_enrollment_latest_start_on,
        open_enrollment_latest_end_on: open_enrollment_latest_end_on,
        binder_payment_due_date: binder_payment_due_date
      }

      timetable
    end

    def check_start_on(start_on)
      start_on = start_on.to_date
      shop_enrollemnt_times = shop_enrollment_timetable(start_on)

      if start_on.day != 1
        result = "failure"
        msg = "start on must be first day of the month"
      elsif Date.current > shop_enrollemnt_times[:open_enrollment_latest_start_on]
        result = "failure"
        msg = "start on must choose a start on date #{(Date.current - HbxProfile::ShopOpenEnrollmentBeginDueDayOfMonth + HbxProfile::ShopOpenEnrollmentPeriodMaximum.months).beginning_of_month} or later"
      end
      {result: (result || "ok"), msg: (msg || "")}
    end

    def calculate_start_on_options
      start_at = (Date.current - HbxProfile::ShopOpenEnrollmentBeginDueDayOfMonth + HbxProfile::ShopOpenEnrollmentPeriodMaximum.months).beginning_of_month
      end_at = (Date.current + HbxProfile::ShopPlanYearPublishBeforeEffectiveDateMaximum).beginning_of_month
      dates = (start_at..end_at).select {|t| t == t.beginning_of_month}
      dates.map {|date| [date.strftime("%B %Y"), date.to_s(:db) ]}
    end

    def calculate_open_enrollment_date(start_on)
      start_on = start_on.to_date
      open_enrollment_start_on = [(start_on - HbxProfile::ShopOpenEnrollmentPeriodMaximum.months), Date.current].max
      open_enrollment_end_on = open_enrollment_start_on + 10.days

      {open_enrollment_start_on: open_enrollment_start_on,
       open_enrollment_end_on: open_enrollment_end_on}
    end

    ## TODO - add holidays
    def first_banking_date_prior(date_value)
      date = date_value.to_date
      date = date - 1 if date.saturday?
      date = date - 2 if date.sunday?
      date
    end
  end

  aasm do
    state :draft, initial: true
    state :publish_pending # Plan application was submitted has warnings
    state :published,      # Plan has been finalized and is ready to be enrolled
          :after_enter => :register_employer
    state :enrolling       # Published plan has entered open enrollment
    state :enrolled        # Published plan has completed open enrollment but date is before start of plan year
    state :canceled        # Non-compliant for enrollment
    state :active          # Published plan year is in force
    state :retired         # Published plans are retired following their end on date
    state :expired         # Non-published plans are expired following their end on date

    event :advance_application_date, :guard => :is_new_plan_year? do
      transitions from: :draft, to: :expired
      transitions from: :active, to: :retired
      transitions from: :published, to: :active
    end

    # Submit application
    event :publish do
      transitions from: :draft, to: :published, :guard => :is_application_valid?
      transitions from: :draft, to: :publish_pending
    end

    # Returns plan to draft state for edit
    event :withdraw_pending do
      transitions from: :publish_pending, to: :draft
    end

    # Plan with application warnings submitted to HBX
    event :force_publish do
      transitions from: :publish_pending, to: :published
    end

    # Permanently disable this plan year
    event :deactivate do
      transitions from: :draft, to: :expired
      transitions from: :active, to: :retired
    end

    #
    event :revert do
      transitions from: :published, to: :draft
    end
  end

  def is_eligible_to_match_census_employees?
    (benefit_groups.size > 0) and
    (published? or enrolling? or enrolled? or active?)
  end

  # def shoppable? # is_eligible_to_shop?
  #   (benefit_groups.size > 0) and
  #   ((published? and employer_profile.shoppable?))
  # end

  def is_eligible_to_enroll?
    (benefit_groups.size > 0) and
    (published? and employer_profile.is_eligible_to_enroll?)
  end

private
  def is_new_plan_year?
  end

  def duration_in_days(duration)
    (duration / 1.day).to_i
  end

  def open_enrollment_date_checks
    return if start_on.blank? || end_on.blank? || open_enrollment_start_on.blank? || open_enrollment_end_on.blank?
    if start_on.day != 1
      errors.add(:start_on, "must be first day of the month")
    end

    if end_on != Date.civil(end_on.year, end_on.month, -1)
      errors.add(:end_on, "must be last day of the month")
    end

    # TODO: Create HBX object with configuration settings including shop_plan_year_maximum_in_days
    shop_plan_year_maximum_in_days = 365
    if (end_on.yday - start_on.yday) > shop_plan_year_maximum_in_days
      errors.add(:end_on, "must be less than #{shop_plan_year_maximum_in_days} days from start date")
    end

    if open_enrollment_end_on > start_on
      errors.add(:start_on, "can't occur before open enrollment end date")
    end

    # if Date.current > ("#{prior_month.year}-#{prior_month.month}-#{HbxProfile::ShopOpenEnrollmentBeginDueDayOfMonth}").to_date
    #  errors.add(:start_on, "must choose a start on date #{effect_date + 1.month} or later")
    # end

    if open_enrollment_end_on < open_enrollment_start_on
      errors.add(:open_enrollment_end_on, "can't occur before open enrollment start date")
    end

    if (open_enrollment_end_on.yday - open_enrollment_start_on.yday) < HbxProfile::ShopOpenEnrollmentPeriodMinimum
     errors.add(:open_enrollment_end_on, "open enrollment period is less than minumum: #{HbxProfile::ShopOpenEnrollmentPeriodMinimum} days")
    end

    if (open_enrollment_end_on - open_enrollment_start_on) > HbxProfile::ShopOpenEnrollmentPeriodMaximum.months
     errors.add(:open_enrollment_end_on, "open enrollment period is greater than maximum: #{HbxProfile::ShopOpenEnrollmentPeriodMaximum} months")
    end

    if start_on + HbxProfile::ShopPlanYearPeriodMinimum < end_on
      errors.add(:end_on, "plan year period is less than minumum: #{duration_in_days(HbxProfile::ShopPlanYearPeriodMinimum)} days")
    end

    if start_on + HbxProfile::ShopPlanYearPeriodMaximum > end_on
      errors.add(:end_on, "plan year period is greater than maximum: #{duration_in_days(HbxProfile::ShopPlanYearPeriodMaximum)} days")
    end

    if (start_on - HbxProfile::ShopPlanYearPublishBeforeEffectiveDateMaximum) > Date.current
     errors.add(:start_on, "may not start application before " \
        "#{(start_on - HbxProfile::ShopPlanYearPublishBeforeEffectiveDateMaximum).to_date} with #{start_on} effective date")
    end

    if open_enrollment_end_on - (start_on - 1.month) >= HbxProfile::ShopOpenEnrollmentEndDueDayOfMonth
     errors.add(:open_enrollment_end_on, "open enrollment must end on or before the #{HbxProfile::ShopOpenEnrollmentEndDueDayOfMonth.ordinalize} day of the month prior to effective date")
    end

  end
end
