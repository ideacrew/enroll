class HbxProfile

  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps

  embedded_in :organization

  field :cms_id, type: String
  field :us_state_abbreviation, type: String

  delegate :legal_name, :legal_name=, to: :organization, allow_nil: true
  delegate :dba, :dba=, to: :organization, allow_nil: true
  delegate :fein, :fein=, to: :organization, allow_nil: true
  delegate :entity_kind, :entity_kind=, to: :organization, allow_nil: true

  embeds_many :hbx_staff_roles
  embeds_many :enrollment_periods # TODO: deprecated - should be removed by 2015-09-03 - Sean Carley

  embeds_one :benefit_sponsorship, cascade_callbacks: true
  embeds_one :inbox, as: :recipient, cascade_callbacks: true

  accepts_nested_attributes_for :inbox, :benefit_sponsorship

  validates_presence_of :us_state_abbreviation, :cms_id

  after_initialize :build_nested_models

  def advance_day
  end

  def advance_month
  end

  def advance_quarter
  end

  def advance_year
  end

  def under_open_enrollment?
    (benefit_sponsorship.present? && benefit_sponsorship.is_under_open_enrollment?) ?  true : false
  end

  def active_employers
    EmployerProfile.active
  end

  def inactive_employers
    EmployerProfile.inactive
  end

  def active_employees
    CensusEmployee.active
  end

  def active_broker_agencies
    BrokerAgencyProfile.active
  end

  def inactive_broker_agencies
    BrokerAgencyProfile.inactive
  end

  def active_brokers
    BrokerRole.active
  end

  def inactive_brokers
    BrokerRole.inactive
  end

  class << self
    def find(id)
      org = Organization.where("hbx_profile._id" => BSON::ObjectId.from_string(id)).first
      org.hbx_profile if org.present?
    end

    def find_by_cms_id(id)
      org = Organization.where("hbx_profile.cms_id": id).first
      org.hbx_profile if org.present?
    end

    def find_by_state_abbreviation(state)
      org = Organization.where("hbx_profile.us_state_abbreviation": state.to_s.upcase).first
      org.hbx_profile if org.present?
    end

    def all
      Organization.exists(hbx_profile: true).all.reduce([]) { |set, org| set << org.hbx_profile }
    end

    def current_hbx
      find_by_state_abbreviation("DC")
    end

    ###
    def build_grid_values_for_aptc_csr(family)
        months_array = Date::ABBR_MONTHNAMES.compact
        plan_premium_vals         = build_plan_premium_values(family, months_array)
        aptc_applied_vals         = build_aptc_applied_values(family, months_array)
        avalaible_aptc_vals       = build_avalaible_aptc_values(family, months_array)
        max_aptc_vals             = build_max_aptc_values(family, months_array)
        csr_percentage_vals       = build_csr_percentage_values(family, months_array)
        slcsp_values              = build_slcsp_values(family, months_array)
        individuals_covered_vals  = build_individuals_covered_array(family, months_array)
        eligible_members_vals     = build_eligible_members(family, months_array)

        return { "plan_premium"         => plan_premium_vals,
                 "aptc_applied"         => aptc_applied_vals,
                 "avalaible_aptc"       => avalaible_aptc_vals,
                 "max_aptc"             => max_aptc_vals,
                 "csr_percentage"       => csr_percentage_vals,
                 "slcsp"                => slcsp_values, 
                 "individuals_covered"  => individuals_covered_vals,
                 "eligible_members"     => eligible_members_vals 
                }
    end

    def build_plan_premium_values(family, months_array)
      hbx = family.active_household.hbx_enrollments_with_aptc_by_year(TimeKeeper.datetime_of_record.year).last

      plan_premium_hash = Hash.new
      months_array.each_with_index do |month, ind|
        plan_premium_hash.store(month, hbx.try(:total_premium) || false)
      end
      return plan_premium_hash
    end

    def build_aptc_applied_values(family, months_array)
      #hbxs = family.active_household.hbx_enrollments_with_aptc_by_year(TimeKeeper.datetime_of_record.year)
      eligibility_determinations = family.active_household.latest_active_tax_household.eligibility_determinations
      #applied_aptc = hbxs.map{|h| h.applied_aptc_amount.to_f}.sum
      aptc_applied_hash = Hash.new
      months_array.each_with_index do |month, ind|
        eligibility_determinations.each do |ed|
          update_aptc_applied_hash_for_month(aptc_applied_hash, month, ed, family)
          #aptc_applied_hash.store(month, applied_aptc)
        end
      end
      return aptc_applied_hash
    end

    def update_aptc_applied_hash_for_month(aptc_applied_hash, month, ed, family)
      hbxs = family.active_household.hbx_enrollments_with_aptc_by_year(TimeKeeper.datetime_of_record.year)
      applied_aptc = hbxs.map{|h| h.applied_aptc_amount.to_f}.sum
      first_of_month_num_current_year = first_of_month_converter(month)
      if first_of_month_num_current_year >= ed.determined_on
        aptc_applied_hash.store(month, applied_aptc)
      else
        aptc_applied_hash.store(month, "---")
      end  
    end


    def build_avalaible_aptc_values(family, months_array)

      available_aptc_hash = Hash.new
      eligibility_determinations = family.active_household.latest_active_tax_household.eligibility_determinations

      months_array.each_with_index do |month, ind|
        eligibility_determinations.each do |ed|

          update_available_aptc_hash_for_month(available_aptc_hash, month, ed, family)
        #avalaible_aptc_hash.store(month, family.active_household.latest_active_tax_household.total_aptc_available_amount)
        end
      end
      return available_aptc_hash
    end

    def update_available_aptc_hash_for_month(available_aptc_hash, month, ed, family)
      first_of_month_num_current_year = first_of_month_converter(month)
      if first_of_month_num_current_year >= ed.determined_on
        available_aptc_hash.store(month, family.active_household.latest_active_tax_household.total_aptc_available_amount)
      else
        available_aptc_hash.store(month, "---")
      end  
    end

    def build_max_aptc_values(family, months_array)
      max_aptc_hash = Hash.new
      eligibility_determinations = family.active_household.latest_active_tax_household.eligibility_determinations
      months_array.each_with_index do |month, ind|
        # iterate over all the EligibilityDeterminations and store the correct max_aptc value for each month. Account for any monthly change in Eligibility Determination.
        eligibility_determinations.each do |ed|
          update_max_aptc_hash_for_month(max_aptc_hash, month, ed)
        end  
        #max_aptc_hash.store(month, family.active_household.tax_households[0].eligibility_determinations.first.max_aptc.fractional)
        #max_aptc_hash.store(month, family.active_household.latest_active_tax_household.current_max_aptc.to_f)
      end
      return max_aptc_hash
    end

    def update_max_aptc_hash_for_month(max_aptc_hash, month, ed)
      first_of_month_num_current_year = first_of_month_converter(month)
      # Check if  'month' >= EligibilityDetermination.determined_on date?
      if first_of_month_num_current_year >= ed.determined_on
        # assign that month with aptc_max value from this ed (EligibilityDetermination)
        max_aptc_hash.store(month, ed.max_aptc.to_f)
      else
        # update max_aptc value for that month as a "---"
        max_aptc_hash.store(month, "---")
      end  
    end



    def build_csr_percentage_values(family, months_array)
      csr_percentage_hash = Hash.new
      eligibility_determinations = family.active_household.latest_active_tax_household.eligibility_determinations
      months_array.each_with_index do |month, ind|
        eligibility_determinations.each do |ed|
          update_csr_percentages_hash_for_month(csr_percentage_hash, month, ed)
        end 
        #csr_percentage_hash.store(month, (family.active_household.latest_active_tax_household.current_csr_percent*100).to_s + " %")
      end
      return csr_percentage_hash
    end

    def update_csr_percentages_hash_for_month(csr_percentage_hash, month, ed)
      first_of_month_num_current_year = first_of_month_converter(month)
      # Check if  'month' >= EligibilityDetermination.determined_on date?
      if first_of_month_num_current_year >= ed.determined_on
        # assign that month with csr_percent value from this ed (EligibilityDetermination)
        csr_percentage_hash.store(month, ed.csr_percent_as_integer)
      else
        # update csr_percent value for that month as a "-"
        csr_percentage_hash.store(month, "---")
      end  
    end

    def first_of_month_converter(month)
      month_num = Date::ABBR_MONTHNAMES.index(month.capitalize || month) # coverts Month name to Month Integer : "jan" -> 1
      current_year = TimeKeeper.date_of_record.year
      first_of_month_num_current_year = Date.parse("#{current_year}-#{month_num}-01")
      return first_of_month_num_current_year
    end  

    def build_slcsp_values(family, months_array)
      benefit_sponsorship = HbxProfile.current_hbx.benefit_sponsorship
      eligibility_determinations = family.active_household.latest_active_tax_household.eligibility_determinations
      benefit_coverage_period = benefit_sponsorship.benefit_coverage_periods.detect {|bcp| bcp.contains?(TimeKeeper.datetime_of_record)}
      slcsp = benefit_coverage_period.second_lowest_cost_silver_plan
      aptc_members = family.active_household.latest_active_tax_household.aptc_members
      cost = aptc_members.map do |member|
        slcsp.premium_for(TimeKeeper.datetime_of_record, member.age_on_effective_date)
      end.inject(:+) || 0
          
      slcsp_hash = Hash.new
      months_array.each_with_index do |month, ind|
        eligibility_determinations.each do |ed|
          first_of_month_num_current_year = first_of_month_converter(month)
            if first_of_month_num_current_year >= ed.determined_on
              slcsp_hash.store(month, cost)
            else
              slcsp_hash.store(month, "---")
            end  
          
        end
      end
      return slcsp_hash
    end

    def build_individuals_covered_array(family, months_array)
      individuals_covered_array = Array.new
      eligibility_determinations = family.active_household.latest_active_tax_household.eligibility_determinations
      family.family_members.each_with_index do |one_member, index|
          covered_hash = Hash.new
            months_array.each_with_index do |month, ind|
                eligibility_determinations.each do |ed|
                  first_of_month_num_current_year = first_of_month_converter(month)
                  if first_of_month_num_current_year >= ed.determined_on
                    covered_hash.store(month, true)
                  else
                    covered_hash.store(month, false)
                  end 
                end
            end
           individuals_covered_array << {one_member.person.id.to_s => covered_hash} 
      end
      return individuals_covered_array
    end


    def build_eligible_members(family, months_array)
      eligible_members = Array.new
      tax_household_members = family.active_household.latest_active_tax_household_with_year(TimeKeeper.date_of_record.year).try(:tax_household_members)
      tax_household_members.each do |member|
        if member.is_ia_eligible
          eligible_members << member.person.id.to_s
        end
      end
      return eligible_members
    end
    ###

  end

  ## Application-level caching

  ## HBX general settings
  StateName = "District of Columbia"
  StateAbbreviation = "DC"
  CallCenterName = "DC Health Link's Customer Care Center"
  CallCenterPhoneNumber = "1-855-532-5465"
  ShortName = "DC Health Link"

  # IndividualEnrollmentDueDayOfMonth = 15
  # Temporary change for Dec 2015 extension
  IndividualEnrollmentDueDayOfMonth = 18
  IndividualEnrollmentTerminationMinimum = 14.days

  InitialEmployerPlanYearPublishDueDayOfMonth = 5
  RenewingEmployerPlanYearPublishDueDayOfMonth = 10

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
  # ShopRetroactiveTerminationMaximum = 60.days
  #
  # # Length of time preceeding next effective date that an employer may renew
  # ShopMaximumRenewalPeriodBeforeStartOn = 3.months
  #
  # # Length of time preceeding effective date that an employee may submit a plan enrollment
  # ShopMaximumEnrollmentPeriodBeforeEligibilityInDays = 30
  #
  # # Length of time following effective date that an employee may submit a plan enrollment
  # ShopMaximumEnrollmentPeriodAfterEligibilityInDays = 30
  #
  # # Minimum number of days an employee may submit a plan, following addition or correction to Employer roster
  # ShopMinimumEnrollmentPeriodAfterRosterEntryInDays = 30
  #
  # # TODO - turn into struct that includes count, plus effective date range
  # ShopApplicationAppealPeriodMaximum = 30.days
  #
  # # After submitting an ineligible plan year application, time period an Employer must wait
  # #   before submitting a new application
  # ShopApplicationIneligiblePeriodMaximum = 90.days
  #
  # # TODO - turn into struct that includes count, plus effective date range
  # ShopSmallMarketFteCountMaximum = 50
  #
  # ## SHOP enrollment-related periods in days
  # # Minimum number of days for SHOP open enrollment period
  # ShopOpenEnrollmentPeriodMinimum = 5
  # ShopOpenEnrollmentEndDueDayOfMonth = 10
  #
  # # Maximum number of months for SHOP open enrollment period
  # ShopOpenEnrollmentPeriodMaximum = 2
  #
  # # Minumum length of time for SHOP Plan Year
  # ShopPlanYearPeriodMinimum = 1.year - 1.day
  #
  # # Maximum length of time for SHOP Plan Year
  # ShopPlanYearPeriodMaximum = 1.year - 1.day
  #
  # # Maximum number of months prior to coverage effective date to submit a Plan Year application
  # ShopPlanYearPublishBeforeEffectiveDateMaximum = 3.months
  #
  # ShopEmployerContributionPercentMinimum = 50.0
  # ShopEnrollmentParticipationRatioMinimum = 2 / 3.0
  # ShopEnrollmentNonOwnerParticipationMinimum = 1
  #
  # ShopBinderPaymentDueDayOfMonth = 15
  # ShopRenewalOpenEnrollmentEndDueDayOfMonth = 13


  ShopOpenEnrollmentBeginDueDayOfMonth = Settings.aca.shop_market.open_enrollment.monthly_end_on - Settings.aca.shop_market.open_enrollment.minimum_length.days
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
    welcome_subject = "Welcome to #{Settings.site.short_name}"
    welcome_body = "#{Settings.site.short_name} is the #{Settings.aca.state_name}'s on-line marketplace to shop, compare, and select health insurance that meets your health needs and budgets."
    @inbox.save
    @inbox.messages.create(subject: welcome_subject, body: welcome_body)
  end


end
