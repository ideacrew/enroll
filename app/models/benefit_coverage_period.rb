# A time period during which Organizations, including {HbxProfile}, who are eligible for a {BenefitSponsorship}, may offer
# {BenefitPackage}(s) to participants within a market place. Each {BenefitCoveragePeriod} includes an open enrollment
# period, during which eligible partipants may enroll.

class BenefitCoveragePeriod
  include Mongoid::Document
  include Mongoid::Timestamps
  include GlobalID::Identification

  embedded_in :benefit_sponsorship

  # This Benefit Coverage Period's name
  field :title, type: String

  # Market where benefits are available
  field :service_market, type: String

  field :start_on, type: Date
  field :end_on, type: Date
  field :open_enrollment_start_on, type: Date
  field :open_enrollment_end_on, type: Date

  # Second Lowest Cost Silver Plan, by rating area (only one rating area in DC)
  field :slcsp, type: BSON::ObjectId
  field :slcsp_id, type: BSON::ObjectId

  # embeds_many :open_enrollment_periods, class_name: "EnrollmentPeriod"
  embeds_many :benefit_packages
  embeds_many :eligibilities, class_name: '::Eligible::Eligibility', as: :eligible, cascade_callbacks: true

  accepts_nested_attributes_for :benefit_packages

  validates_presence_of :start_on, :end_on, :open_enrollment_start_on, :open_enrollment_end_on, message: "is invalid"

  validates :service_market,
    inclusion: { in: BenefitSponsorship::SERVICE_MARKET_KINDS, message: "%{value} is not a valid service market" }

  validate :end_date_follows_start_date

  before_save :set_title

  scope :by_date, ->(date) { where({:"start_on".lte => date, :"end_on".gte => date}) }

  scope :by_year, ->(year) { where(start_on: (Date.new(year)..Date.new(year).end_of_year)) }

  # Gets the successor coverage period.
  # @return [BenefitCoveragePeriod, nil] the successor
  def successor
    benefit_sponsorship.benefit_coverage_periods.detect do |bcp|
      (self.end_on + 1.day) == bcp.start_on
    end
  end

  # Sets the ACA Second Lowest Cost Silver Plan (SLCSP) reference plan
  #
  # @raise [ArgumentError] if the referenced plan is not silver metal level
  #
  # @param new_plan [ Plan ] The reference plan.
  def second_lowest_cost_silver_plan=(new_plan)
    raise ArgumentError, 'expected Plan' unless new_plan.is_a?(BenefitMarkets::Products::Product)
    raise ArgumentError.new("slcsp metal level must be silver") unless new_plan.metal_level == "silver"
    self.slcsp_id = new_plan._id
    self.slcsp = new_plan._id
    @second_lowest_cost_silver_plan = new_plan
  end

  # Gets the ACA Second Lowest Cost Silver Plan (SLCSP) reference plan
  #
  # @return [ Plan ] reference plan
  def second_lowest_cost_silver_plan
    return @second_lowest_cost_silver_plan if defined? @second_lowest_cost_silver_plan
    @second_lowest_cost_silver_plan = product_factory.new({product_id: slcsp_id}).product if slcsp_id.present?
  end

  # @todo Available products from which this sponsor may offer benefits during this benefit coverage period
  def benefit_products
  end

  # Sets the earliest coverage effective date
  #
  # @overload start_on=(new_date)
  #
  # @param new_date [ Date ] The earliest coverage effective date
  def start_on=(new_date)
    new_date = Date.parse(new_date) if new_date.is_a? String
    write_attribute(:start_on, new_date.beginning_of_day)
  end

  # Sets the latest date a participant may enroll for coverage
  #
  # @overload end_on=(new_date)
  #
  # @param new_date [ Date ] The latest date a participant may enroll for coverage
  def end_on=(new_date)
    new_date = Date.parse(new_date) if new_date.is_a? String
    write_attribute(:end_on, new_date.end_of_day)
  end

  # Determine if this date is within the benefit coverage period start/end dates
  #
  # @example Is the date within the benefit coverage period?
  #   model.contains?(date)
  #
  # @return [ true, false ] true if the date falls within the period, false if the date is outside the period
  def contains?(date)
    (start_on <= date.to_date) && (date.to_date <= end_on)
  end

  # Determine if this date is within the open enrollment period start/end dates
  #
  # @param date [ Date ] The comparision date
  #
  # @example Is the date within the open enrollment period?
  #   model.open_enrollment_contains?(date)
  #
  # @return [ true, false ] true if the date falls within the period, false if the date is outside the period
  def open_enrollment_contains?(date)
    (open_enrollment_start_on <= date) && (date <= open_enrollment_end_on)
  end

  # The earliest enrollment termination effective date, based on this date and site settings
  #
  # @param date [ Date ] The comparision date.
  #
  # @example When is the earliest termination effective date?
  #   model.termination_effective_on_for(date)
  #
  # @return [ Date ] the earliest termination effective date.
  def termination_effective_on_for(date)
    # Add guard to prevent the temination date exceeding end date in the Individual Market
    [date, end_on].min # see 20996
  end

  # The earliest coverage start effective date, based on today's date and site settings
  #
  # @example When is the earliest coverage start effective date?
  #   model.earliest_effective_date
  #
  # @return [ Date ] the earliest coverage start effective date
  def earliest_effective_date
    if TimeKeeper.date_of_record.day <= HbxProfile::IndividualEnrollmentDueDayOfMonth
      effective_date = TimeKeeper.date_of_record.end_of_month + 1.day
    else
      effective_date = TimeKeeper.date_of_record.next_month.end_of_month + 1.day
    end

    [[effective_date, start_on].max, end_on].min
  end

  # Determine list of available products (plans), based on member enrollment eligibility for each {BenefitPackage} under this
  # {BenefitCoveragePeriod}. In the Individual market, BenefitPackage types may include Catastrophic, Cost Sharing
  # Reduction (CSR), etc., and eligibility criteria such as member age, ethnicity, residency and lawful presence.
  #
  # @param hbx_enrollment_members [ Array ] the list of enrolling members
  # @param coverage_kind [ String ] the benefit type.  Only 'health' is currently supported
  # @param tax_household [ TaxHousehold ] if eligible for financial assistance
  #
  # @return [ Array<Plan> ] the list of eligible products

  # TODO: This can be removed once we get rid of temporary config.
  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Style/ConditionalAssignment
  def elected_plans_by_enrollment_members(hbx_enrollment_members, coverage_kind, tax_household = nil, market = nil)
    hbx_enrollment = hbx_enrollment_members.first.hbx_enrollment
    shopping_family_member_ids = hbx_enrollment_members.map(&:applicant_id)
    subcriber = hbx_enrollment_members.detect(&:is_subscriber)
    family_members = hbx_enrollment_members.map(&:family_member)
    american_indian_members = extract_american_indian_status(hbx_enrollment, shopping_family_member_ids)

    if EnrollRegistry.feature_enabled?(:temporary_configuration_enable_multi_tax_household_feature)
      csr_kind = ::Operations::PremiumCredits::FindCsrValue.new.call({ family: hbx_enrollment.family,
                                                                       year: hbx_enrollment.effective_on.year,
                                                                       family_member_ids: shopping_family_member_ids }).value!
    else
      csr_kind = if tax_household
                   extract_csr_kind(tax_household, shopping_family_member_ids)
                 elsif american_indian_members && FinancialAssistanceRegistry.feature_enabled?(:native_american_csr)
                   'csr_limited'
                 end
    end

    ivl_bgs = get_benefit_packages({family_members: family_members, coverage_kind: coverage_kind, family: hbx_enrollment.family, american_indian_members: american_indian_members,
                                    hbx_enrollment: hbx_enrollment,
                                    effective_on: hbx_enrollment.effective_on, market: market, shopping_family_members_ids: shopping_family_member_ids, csr_kind: csr_kind }).uniq
    elected_product_ids = ivl_bgs.map(&:benefit_ids).flatten.uniq
    market = market.nil? || market == 'coverall' ? 'individual' : market
    product_entries({market: market, coverage_kind: coverage_kind, csr_kind: csr_kind, elected_product_ids: elected_product_ids, subcriber: subcriber, effective_on: hbx_enrollment.effective_on})
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Style/ConditionalAssignment

  def get_benefit_packages(attrs)
    any_member_greater_than_30 = attrs[:hbx_enrollment].any_member_greater_than_30?
    fetch_benefit_packages(any_member_greater_than_30, attrs[:csr_kind], attrs[:coverage_kind]).inject([]) do |result, bg|
      satisfied = true
      attrs[:family_members].each do |family_member|
        consumer_role = family_member.person.consumer_role if family_member.person.is_consumer_role_active?
        resident_role = family_member.person.resident_role if family_member.person.is_resident_role_active?
        rule = if resident_role.nil?
                 InsuredEligibleForBenefitRule.new(consumer_role, bg, { coverage_kind: attrs[:coverage_kind], family: attrs[:family],
                                                                        new_effective_on: attrs[:effective_on],  market_kind: attrs[:market], shopping_family_members_ids: attrs[:shopping_family_members_ids], csr_kind: attrs[:csr_kind]})
               else
                 InsuredEligibleForBenefitRule.new(resident_role, bg, coverage_kind: attrs[:coverage_kind], family: attrs[:family], market_kind: attrs[:market], shopping_family_members_ids: attrs[:shopping_family_members_ids],
                                                                      csr_kind: attrs[:csr_kind])
               end
        satisfied = false and break unless rule.satisfied?[0]
      end
      result << bg if satisfied
      result
    end
  end

  def product_entries(attrs)
    factory = product_factory.new({market_kind: attrs[:market]})
    elected_products = factory.by_coverage_kind_year_and_csr(attrs[:coverage_kind], start_on.year, csr_kind: attrs[:csr_kind]).by_product_ids(attrs[:elected_product_ids])

    if EnrollRegistry[:service_area].settings(:service_area_model).item == 'single'
      elected_products.entries
    else
      person = attrs[:subcriber].family_member.person
      address = person.home_address || person.mailing_address
      service_area_ids = ::BenefitMarkets::Locations::ServiceArea.service_areas_for(address, during: attrs[:effective_on]).map(&:id)
      elected_products.where(:service_area_id.in => service_area_ids).entries
    end
  end

  def dental_benefit_package
    benefit_packages.detect { |bp| bp.benefit_categories.include?('dental') }
  end

  def fetch_benefit_packages(any_member_greater_than_30, csr_kind, coverage_kind = "health")
    return [dental_benefit_package] if coverage_kind == 'dental'

    return benefit_packages.select { |bp| bp.cost_sharing == '' && bp.benefit_categories.include?('health') } if csr_kind.blank?

    eligible_packages = benefit_packages.select { |bp| [csr_kind, 'csr_0'].include?(bp.cost_sharing) }
    return eligible_packages if any_member_greater_than_30

    cat_benefit_package = benefit_packages.select { |bp| bp.title.match?(/catastrophic_health_benefits/i) }.last
    return eligible_packages if cat_benefit_package.blank?

    eligible_packages.push(cat_benefit_package)
  end

  def eligibilities_on(date)
    eligibility_key = "aca_ivl_osse_eligibility_#{date.year}".to_sym

    eligibilities.by_key(eligibility_key)
  end

  def eligibility_on(effective_date)
    eligibilities_on(effective_date).last
  end

  def active_eligibilities_on(date)
    eligibilities_on(date).select { |e| e.is_eligible_on?(date) }
  end

  def active_eligibility_on(effective_date)
    active_eligibilities_on(effective_date).last
  end

  ## Class methods
  class << self

    # The HBX benefit coverage period instance for this identifier
    #
    # @param id [ String ] the BSON object identifier
    #
    # @example Which HBX benefit coverage period matches this id?
    #   BenefitCoveragePeriod.find(id)
    #
    # @return [ BenefitCoveragePeriod ] the matching HBX benefit coverage period instance
    def find(id)
      organizations = Organization.where("hbx_profile.benefit_sponsorship.benefit_coverage_periods._id" => BSON::ObjectId.from_string(id))
      return unless organizations.present?
      hbx_profile = organizations.first.hbx_profile
      benefit_sponsorship = hbx_profile&.benefit_sponsorship
      benefit_sponsorship&.benefit_coverage_periods&.find(BSON::ObjectId.from_string(id))
    end

    # The HBX benefit coverage period instance that includes this date within its start and end dates
    #
    # @param date [ Date ] the comparison date
    #
    # @example Which HBX benefit coverage period covers this date?
    #   BenefitCoveragePeriod.find_by_date(date)
    #
    # @return [ BenefitCoveragePeriod ] the matching HBX benefit coverage period instance
    def find_by_date(date)
      organizations = Organization.where(
        :"hbx_profile.benefit_sponsorship.benefit_coverage_periods.start_on".lte => date,
        :"hbx_profile.benefit_sponsorship.benefit_coverage_periods.end_on".gte => date)
      if organizations.size > 0
        bcps = organizations.first.hbx_profile.benefit_sponsorship.benefit_coverage_periods
        bcps.select{ |bcp| bcp.start_on <= date && bcp.end_on >= date }.first
      else
        nil
      end
    end

    # All HBX benefit coverage periods
    #
    # @example Which HBX benefit coverage periods are defined?
    #   BenefitCoveragePeriod.all
    #
    # @return [ Array ] the list of HBX benefit coverage periods
    def all
      organizations = Organization.exists(:"hbx_profile.benefit_sponsorship.benefit_coverage_periods" => true)
      organizations.size > 0 ? organizations.first.hbx_profile.benefit_sponsorship.benefit_coverage_periods : nil
    end

    #TODO: update the logic once settings moved to benefit coverage period
    def osse_eligibility_years_for_display
      return [] if all.blank?
      all.collect do |bcp|
        year = bcp.start_on.year
        eligibility = bcp.eligibilities.by_key("aca_ivl_osse_eligibility_#{year}".to_sym).first
        next unless eligibility&.eligible?
        year
      end.compact
    end
  end

  private

  def extract_csr_kind(tax_household, shopping_family_member_ids)
    tax_household.eligibile_csr_kind(shopping_family_member_ids)
  end

  def end_date_follows_start_date
    return unless self.end_on.present?
    # Passes validation if end_on == start_date
    errors.add(:end_on, "end_on cannot preceed start_on date") if self.end_on < self.start_on
  end

  def set_title
    return if title.present?
    service_market == "shop" ? market_name = "SHOP" : market_name = "Individual"
    self.title = "#{market_name} Market Benefits #{start_on.year}"
  end

  def product_factory
    ::BenefitMarkets::Products::ProductFactory
  end

  def extract_american_indian_status(hbx_enrollment, shopping_family_members_ids)
    shopping_family_members = hbx_enrollment.family.family_members.where(:id.in => shopping_family_members_ids)
    shopping_family_members.all?{|fm| fm.person.indian_tribe_member }
  end
end
