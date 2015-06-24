class HbxProfile
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :organization
  embeds_many :hbx_staff_roles
  embeds_many :enrollment_periods
  embeds_one :inbox, as: :recipient
  accepts_nested_attributes_for :inbox

  field :cms_id, type: String
  field :markets, type: Array, default: []

  delegate :legal_name, :legal_name=, to: :organization, allow_nil: true
  delegate :dba, :dba=, to: :organization, allow_nil: true
  delegate :fein, :fein=, to: :organization, allow_nil: true
  delegate :entity_kind, :entity_kind=, to: :organization, allow_nil: true

  after_initialize :build_nested_models

  class << self
    def find(id)
      Organization.where("hbx_profile._id" => BSON::ObjectId.from_string(id)).first.hbx_profile
    end

    def all
      Organization.exists(hbx_profile: true).all.reduce([]) { |set, org| set << org.hbx_profile }
    end
  end

  ## Application-level caching

  ## HBX general settings
  StateName = "District of Columbia"
  StateAbbreviation = "DC"

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
  ShopRetroactiveTerminationMaximum = 60.days

  # Number of days preceeding effective date that an employee may submit a plan enrollment
  ShopMaximumEnrollmentPeriodBeforeEligibilityInDays = 30

  # Minimum number of days an employee may submit a plan, following addition or correction to Employer roster
  ShopMinimumEnrollmentPeriodAfterRosterEntryInDays = 30

  # TODO - turn into struct that includes count, plus effective date range
  ShopSmallMarketFteCountMaximum = 50

  ## SHOP enrollment-related periods in days
  # Minimum number of days for SHOP open enrollment period
  ShopOpenEnrollmentPeriodMinimum = 5

  # Maximum number of months for SHOP open enrollment period
  ShopOpenEnrollmentPeriodMaximum = 2

  # Minumum length of time for SHOP Plan Year
  ShopPlanYearPeriodMinimum = 1.year - 1.day

  # Maximum length of time for SHOP Plan Year
  ShopPlanYearPeriodMaximum = 1.year - 1.day

  # Maximum number of months prior to coverage effective date to submit a Plan Year application
  ShopPlanYearPublishBeforeEffectiveDateMaximum = 3.months

  ShopEmployerContributionPercentMinimum = 50.0
  ShopEnrollmentParticipationRatioMinimum = 2 / 3.0
  ShopEnrollmentNonOwnerParticipationMinimum = 1

  ShopBinderPaymentDueDayOfMonth = 15
  ShopOpenEnrollmentEndDueDayOfMonth = 10
  ShopOpenEnrollmentBeginDueDayOfMonth = ShopOpenEnrollmentEndDueDayOfMonth - ShopOpenEnrollmentPeriodMinimum
  ShopPlanYearPublishedDueDayOfMonth = ShopOpenEnrollmentBeginDueDayOfMonth


  # ShopOpenEnrollmentStartMax
  # EffectiveDate

  # CoverageEffectiveDate - no greater than 3 calendar months max
  # ApplicationPublished latest date - 5th end_of_day  of preceding month

  # OpenEnrollment earliest start - 2 calendar months preceding CoverageEffectiveDate
  # OpenEnrollment min length - 5 days
  # OpenEnrollment latest start date - 5th of month
  # OpenEnrollmentLatestEnd -- 10th day of month prior to effective date
  # BinderPaymentDueDate -- 15th or earliest banking day prior

  private
  def build_nested_models
    build_inbox if inbox.nil?
  end

  def save_inbox
    welcome_subject = "Welcome to DC HealthLink"
    welcome_body = "DC HealthLink is the District of Columbia's on-line marketplace to shop, compare, and select health insurance that meets your health needs and budgets."
    @inbox.save
    @inbox.messages.create(subject: welcome_subject, body: welcome_body)
  end


end
