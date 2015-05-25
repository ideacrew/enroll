class HbxProfile
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :organization
  embeds_many :hbx_staff_roles
  embeds_many :enrollment_periods

  field :cms_id, type: String
  field :markets, type: Array, default: []

  delegate :legal_name, :legal_name=, to: :organization, allow_nil: true
  delegate :dba, :dba=, to: :organization, allow_nil: true
  delegate :fein, :fein=, to: :organization, allow_nil: true
  delegate :entity_kind, :entity_kind=, to: :organization, allow_nil: true

  ## Application-level caching

  ## Carriers
  # hbx_id, hbx_carrier_id, name, abbrev,

  ## Plans & Premiums
  # hbx_id, hbx_plan_id, hbx_carrier_id, hios_id, year, quarter, name, abbrev, market, type, metal_level, pdf

  ## Cross-reference ID Directory
  # Person
  # Employer
  # BrokerAgency
  # Policy

  ## HBX Policies for IVL Market
  # Open Enrollment periods

  ## SHOP Market HBX Policies
  # Employer Contribution Strategies

  # New hires in initial group that start after enrollment, but prior to coverage effective date.  Don't 
  # transmit EDI prior to Employer coverage effective date


  # Maximum number of days an Employer may notify HBX of termination
  # may terminate an employee and effective date
  ShopRetroactiveTerminationMaximumInDays = 60

  # Number of days preceeding effective date that an employee may submit a plan enrollment
  ShopMaximumEnrollmentPeriodBeforeEligibilityInDays = 30

  # Minimum number of days an employee may submit a plan, following addition or correction to Employer roster
  ShopMinimumEnrollmentPeriodAfterRosterEntryInDays = 30

  # TODO - turn into struct that includes count, plus effective date range
  ShopSmallMarketFteCountMaximum = 50

  ## SHOP enrollment-related periods in days
  # Minimum number of days for SHOP open enrollment period
  ShopOpenEnrollmentPeriodMinimum = 5

  # Maximum number of days for SHOP open enrollment period
  ShopOpenEnrollmentPeriodMaximum = 60

  # Minumum length of time for SHOP Plan Year
  ShopPlanYearPeriodMinimum = 365 #1.year

  # Maximum length of time for SHOP Plan Year
  ShopPlanYearPeriodMaximum = 365 #1.year

  # Maximum number of days prior to coverage effective date that a Plan Year may be defined 
  ShopPlanYearPublishBeforeEffectiveDateMaximum = 90

  ShopEmployerContributionPercentMinimum = 50
  ShopEnrollmentParticipationMinimum = 2 / 3.0
  ShopEnrollmentNonFamilyParticipationMinimum = 1

  ShopBinderPaymentDueDayOfMonth = 15
  ShopOpenEnrollmentEndDueDayOfMonth = 10
  ShopOpenEnrollmentBeginDueDayOfMonth = ShopOpenEnrollmentEndDueDayOfMonth - ShopOpenEnrollmentPeriodMinimum
  ShopPlanYearPublishedDueDayOfMonth = ShopOpenEnrollmentBeginDueDayOfMonth

  def shop_schedule_report

  end

  # ShopOpenEnrollmentStartMax
  # EffectiveDate

  # CoverageEffectiveDate - no greater than 3 calendar months max
  # ApplicationPublished latest date - 5th end_of_day  of preceding month 

  # OpenEnrollment earliest start - 2 calendar months preceding CoverageEffectiveDate
  # OpenEnrollment min length - 5 days
  # OpenEnrollment latest start date - 5th of month
  # OpenEnrollmentLatestEnd -- 10th day of month prior to effective date
  # BinderPaymentDueDate -- 15th or earliest banking day prior


end
