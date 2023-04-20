class Plan
  include Mongoid::Document
  include Mongoid::Timestamps
  #  include Mongoid::Versioning
  include Config::AcaModelConcern
  COVERAGE_KINDS = %w[health dental]
  METAL_LEVEL_KINDS = %w[bronze silver gold platinum catastrophic dental]
  REFERENCE_PLAN_METAL_LEVELS = %w[bronze silver gold platinum dental]
  REFERENCE_PLAN_METAL_LEVELS_NO_DENTAL = %w[bronze silver gold platinum].freeze
  MARKET_KINDS = %w(shop individual)
  INDIVIDUAL_MARKET_KINDS = %w(individual coverall)
  PLAN_TYPE_KINDS = %w[pos hmo epo ppo]
  DENTAL_METAL_LEVEL_KINDS = %w[high low]


  field :hbx_id, type: Integer
  field :active_year, type: Integer
  field :market, type: String
  field :coverage_kind, type: String
  field :carrier_profile_id, type: BSON::ObjectId
  field :metal_level, type: String
  field :service_area_id, type: String

  field :hios_id, type: String
  field :hios_base_id, type: String
  field :csr_variant_id, type: String

  field :name, type: String
  field :abbrev, type: String
  field :provider, type: String
  field :ehb, type: Float, default: 0.0
  field :ehb_apportionment_for_pediatric_dental, type: Float

  field :renewal_plan_id, type: BSON::ObjectId
  field :cat_age_off_renewal_plan_id, type: BSON::ObjectId
  field :is_standard_plan, type: Boolean, default: false

  field :minimum_age, type: Integer, default: 0
  field :maximum_age, type: Integer, default: 120

  field :is_active, type: Boolean, default: true
  field :updated_by, type: String

  # TODO deprecate after migrating SBCs for years prior to 2016
  field :sbc_file, type: String
  embeds_one :sbc_document, :class_name => "Document", as: :documentable

  embeds_many :premium_tables
  accepts_nested_attributes_for :premium_tables, :sbc_document

  # To filter plan renewal mapping for carrier
  embeds_many :renewal_plan_mappings

  # More Attributes from qhp
  field :plan_type, type: String  # "POS", "HMO", "EPO", "PPO"
  field :deductible, type: String # Deductible
  field :family_deductible, type: String

  field :network_information, type: String

  field :nationwide, type: Boolean # Nationwide
  field :dc_in_network, type: Boolean # DC In-Network or not

  # Fields for provider direcotry and rx formulary url
  field :provider_directory_url, type: String
  field :rx_formulary_url, type: String

  # for dental plans only, metal level -> high/low values
  field :dental_level, type: String
  field :carrier_special_plan_identifier, type: String

  #field can be used for filtering
  field :frozen_plan_year, type: Boolean

  # Fields for checking respective carrier is offering or not
  field :is_horizontal, type: Boolean, default: -> { true }
  field :is_vertical, type: Boolean, default: -> { true }
  field :is_sole_source, type: Boolean, default: -> { true }

  # In MongoDB, the order of fields in an index should be:
  #   First: fields queried for exact values, in an order that most quickly reduces set
  #   Second: fields used to sort
  #   Third: fields queried for a range of values

  index({ hbx_id: 1, name: 1 })
  index({ hios_id: 1, active_year: 1, name: 1 })
  index({ active_year: 1, market: 1, coverage_kind: 1, nationwide: 1, name: 1 })
  index({ renewal_plan_id: 1, name: 1 })
  index({ name: 1 })
  index({ csr_variant_id: 1}, {sparse: true})

  # 2015, "94506DC0390006-01"
  index(
      {
        active_year: 1,
        hios_id: 1,
        "premium_tables.age": 1,
        "premium_tables.start_on": 1,
        "premium_tables.end_on": 1
      },
      { name: "plan_premium_age" }
    )

  # 92479DC0020002, 2015, 32, 2015-04-01, 2015-06-30
  index({ hios_id: 1, active_year: 1, "premium_tables.age": 1, "premium_tables.start_on": 1, "premium_tables.end_on": 1 }, {name: "plan_premium_age_deprecated"})

  # 2015, individual, health, silver, 04
  index({ active_year: 1, market: 1, coverage_kind: 1, metal_level: 1, csr_variant_id: 1 })

  # 2015, individual, health, gold
  index({ active_year: 1, market: 1, coverage_kind: 1, metal_level: 1, name: 1 })

  # 2015, individual, health, uhc
  index({ active_year: 1, market: 1, coverage_kind: 1, carrier_profile_id: 1, name: 1 })

  # 2015, individual, health, uhc, gold
  index({ active_year: 1, market: 1, coverage_kind: 1, carrier_profile_id: 1, metal_level: 1, name: 1 })

  index({ "premium_tables.age" => 1 })
  index({ "premium_tables.age" => 1, "premium_tables.start_on" => 1, "premium_tables.end_on" => 1 })

  validates_presence_of :name, :hios_id, :active_year, :metal_level, :market, :carrier_profile_id

  validates :coverage_kind,
   allow_blank: false,
   inclusion: {
     in: COVERAGE_KINDS,
     message: "%{value} is not a valid coverage kind"
  }

  validates :metal_level,
   allow_blank: false,
   inclusion: {
     in: METAL_LEVEL_KINDS,
     message: "%{value} is not a valid metal level kind"
  }

  validates :dental_level,
   inclusion: {
     in: DENTAL_METAL_LEVEL_KINDS,
     message: "%{value} is not a valid dental metal level kind"
  }, if: Proc.new{|a| a.active_year.present? && a.active_year > 2015 && a.coverage_kind == "dental" } # we do not check for 2015 plans because, they are already imported with metal_level="dental"

  validates :market,
   allow_blank: false,
   inclusion: {
     in: MARKET_KINDS,
     message: "%{value} is not a valid market"
   }

  validates_inclusion_of :active_year,
    in: 2014..(TimeKeeper.date_of_record.year + 3),
    message: "%{value} is an invalid active year"

  validates_length_of :carrier_special_plan_identifier, minimum: 1, allow_nil: true

  ## Scopes
  default_scope -> {order("name ASC")}

  #filter based on plan offerings
  scope :check_plan_offerings_for_metal_level,  ->{ where(is_horizontal: "true") }
  scope :check_plan_offerings_for_single_carrier,  ->{ where(is_vertical: "true") }
  scope :check_plan_offerings_for_sole_source,  ->{ where(is_sole_source: "true") }

  # Metal level
  scope :platinum_level,      ->{ where(metal_level: "platinum") }
  scope :gold_level,          ->{ where(metal_level: "gold") }
  scope :silver_level,        ->{ where(metal_level: "silver") }
  scope :bronze_level,        ->{ where(metal_level: "bronze") }
  scope :catastrophic_level,  ->{ where(metal_level: "catastrophic") }

  scope :metal_level_sans_silver,  ->{ where(:metal_leval.in => %w(platinum gold bronze catastrophic))}

  # Plan.metal_level_sans_silver.silver_level_by_csr_kind("csr_87")
  scope :silver_level_by_csr_kind, ->(csr_kind = 'csr_0'){ where(
                                          metal_level: "silver").and(
                                          csr_variant_id: EligibilityDetermination::CSR_KIND_TO_PLAN_VARIANT_MAP[csr_kind]
                                        )
                                      }

  # Plan Type
  scope :ppo_plan, ->{ where(plan_type: "ppo") }
  scope :pos_plan, ->{ where(plan_type: "pos") }
  scope :hmo_plan, ->{ where(plan_type: "hmo") }
  scope :epo_plan, ->{ where(plan_type: "epo") }

  # Plan offers local or national in-network benefits
  # scope :national_network,  ->{ where(nationwide: "true") }
  # scope :local_network,     ->{ where(nationwide: "false") }

  scope :by_active_year,        ->(active_year = TimeKeeper.date_of_record.year) { where(active_year: active_year) }
  scope :by_metal_level,        ->(metal_level) { where(metal_level: metal_level) }
  scope :by_dental_level,       ->(dental_level) { where(dental_level: dental_level) }
  scope :by_plan_type,          ->(plan_type) { where(plan_type: plan_type) }
  scope :by_dental_level_for_bqt,       ->(dental_level) { where(:dental_level.in => dental_level) }
  scope :by_plan_type_for_bqt,          ->(plan_type) { where(:plan_type.in => plan_type) }
  scope :for_service_areas,             ->(service_areas) { where(service_area_id: { "$in" => service_areas }) }

  # Marketplace
  scope :shop_market,           ->{ where(market: "shop") }
  scope :individual_market,     ->{ where(market: "individual") }

  scope :health_coverage,       ->{ where(coverage_kind: "health") }
  scope :dental_coverage,       ->{ where(coverage_kind: "dental") }

  # DEPRECATED - 2015-09-23 - By Sean Carley
    # scope :valid_shop_by_carrier, ->(carrier_profile_id) {where(carrier_profile_id: carrier_profile_id, active_year: TimeKeeper.date_of_record.year, market: "shop",  metal_level: {"$in" => ::Plan::REFERENCE_PLAN_METAL_LEVELS})}
    # scope :valid_shop_by_metal_level, ->(metal_level) {where(active_year: TimeKeeper.date_of_record.year, market: "shop", metal_level: metal_level)}
    scope :valid_shop_by_carrier, ->(carrier_profile_id) {valid_shop_by_carrier_and_year(carrier_profile_id, TimeKeeper.date_of_record.year)}
    scope :valid_shop_by_metal_level, ->(metal_level) {valid_shop_by_metal_level_and_year(metal_level, TimeKeeper.date_of_record.year)}

  ## DEPRECATED - 2015-10-26 - By Dan Thomas - Use: individual_health_by_active_year_and_csr_kind
    scope :individual_health_by_active_year, ->(active_year) {where(active_year: active_year, market: "individual", coverage_kind: "health", hios_id: /-01$/ ) }
  # END DEPRECATED

  scope :valid_shop_by_carrier_and_year, ->(carrier_profile_id, year) {
    where(
        carrier_profile_id: carrier_profile_id,
        active_year: year,
        market: "shop",
        hios_id: { "$not" => /-00$/ },
        metal_level: { "$in" => ::Plan::REFERENCE_PLAN_METAL_LEVELS }
      )
  }
  scope :valid_shop_by_metal_level_and_year, ->(metal_level, year) {
    where(
        active_year: year,
        market: "shop",
        hios_id: /-01$/,
        metal_level: metal_level
      )
  }

  scope :with_premium_tables, ->{ where(:premium_tables.exists => true) }


  scope :shop_health_by_active_year, ->(active_year) {
      where(
          active_year: active_year,
          market: "shop",
          coverage_kind: "health"
        )
    }

  scope :shop_dental_by_active_year, ->(active_year) {
      where(
          active_year: active_year,
          market: "shop",
          coverage_kind: "dental"
        )
    }

  scope :individual_health_by_active_year_and_csr_kind, ->(active_year, csr_kind = 'csr_0') {
    where(
      "$and" => [
          {:active_year => active_year, :market => "individual", :coverage_kind => "health"},
          {"$or" => [
                      {:metal_level.in => %w(platinum gold bronze), :csr_variant_id => "01"},
                      {:metal_level => "silver", :csr_variant_id => EligibilityDetermination::CSR_KIND_TO_PLAN_VARIANT_MAP[csr_kind]}
                    ]
            }
        ]
      )
    }

  scope :individual_health_by_active_year_and_csr_kind_with_catastrophic, ->(active_year, csr_kind = 'csr_0') {
    where(
      "$and" => [
          {:active_year => active_year, :market => "individual", :coverage_kind => "health"},
          {"$or" => [
                      {:metal_level.in => %w(platinum gold bronze catastrophic), :csr_variant_id => "01"},
                      {:metal_level => "silver", :csr_variant_id => EligibilityDetermination::CSR_KIND_TO_PLAN_VARIANT_MAP[csr_kind]}
                    ]
            }
        ]
      )
    }

  scope :individual_dental_by_active_year, ->(active_year) {
      where(
          active_year: active_year,
          market: "individual",
          coverage_kind: "dental"
        )
    }

  scope :individual_health_by_active_year_carrier_profile_csr_kind, ->(active_year, carrier_profile_id, csr_kind) {
    where(
      "$and" => [
          {:active_year => active_year, :market => "individual", :coverage_kind => "health", :carrier_profile_id => carrier_profile_id },
          {"$or" => [
                      {:metal_level.in => %w(platinum gold bronze), :csr_variant_id => "01"},
                      {:metal_level => "silver", :csr_variant_id => EligibilityDetermination::CSR_KIND_TO_PLAN_VARIANT_MAP[csr_kind]}
                    ]
            }
        ]
    )
  }

  scope :by_health_metal_levels,                ->(metal_levels)    { any_in(metal_level: metal_levels) }
  scope :by_carrier_profile,                    ->(carrier_profile_id) { where(carrier_profile_id: carrier_profile_id) }
  scope :by_carrier_profile_for_bqt,            ->(carrier_profile_id) { where(:carrier_profile_id.in => carrier_profile_id) }
  scope :with_enabled_metal_levels,             -> { any_in(metal_level: REFERENCE_PLAN_METAL_LEVELS & enabled_metal_levels)}
  scope :health_metal_levels_all,               ->{ any_in(metal_level: REFERENCE_PLAN_METAL_LEVELS << "catastrophic") }
  scope :health_metal_levels_sans_catastrophic, ->{ any_in(metal_level: REFERENCE_PLAN_METAL_LEVELS) }
  scope :health_metal_nin_catastropic,          ->{ not_in(metal_level: "catastrophic") }


  scope :by_plan_ids, ->(plan_ids) { where(:id => {"$in" => plan_ids}) }

  scope :by_nationwide, ->(types) { where(:nationwide => {"$in" => types})}
  # TODO: Refactor this to in_state_network or something similar
  scope :by_dc_network, ->(types) { where(:dc_in_network => {"$in" => types})}

  # TODO: Value is hardcoded for Maine, figure out how to update this
  def in_state_network
    self.dc_in_network
  end

  # Carriers: use class method (which may be chained)
  def self.find_by_carrier_profile(carrier_profile)
    where(carrier_profile_id: carrier_profile._id)
  end

  def self.for_service_areas_and_carriers(service_area_carrier_pairs, active_year, metal_level = nil, coverage_kind = 'health')
    plan_criteria_set = service_area_carrier_pairs.map do |sap|
      criteria = {
        :carrier_profile_id => sap.first,
        :service_area_id => sap.last,
        :active_year => active_year,
        :coverage_kind => coverage_kind
      }
      if metal_level.present?
        criteria.merge(metal_level: metal_level)
      end
      criteria
    end
    self.where("$or" => plan_criteria_set)
  end

  def metal_level=(new_metal_level)
    write_attribute(:metal_level, new_metal_level.to_s.downcase)
  end

  def coverage_kind=(new_coverage_kind)
    write_attribute(:coverage_kind, new_coverage_kind.to_s.downcase)
  end

  # belongs_to CarrierProfile
  def carrier_profile=(new_carrier_profile)
    if new_carrier_profile.nil?
      self.carrier_profile_id = nil
    else
      raise ArgumentError.new("expected CarrierProfile ") unless new_carrier_profile.is_a? CarrierProfile
      self.carrier_profile_id = new_carrier_profile._id
      @carrier_profile = new_carrier_profile
    end
  end

  def carrier_profile
    return @carrier_profile if defined? @carrier_profile
    @carrier_profile = CarrierProfile.find(carrier_profile_id) unless carrier_profile_id.blank?
  end

  def cat_age_off_renewal_plan
    Plan.find(cat_age_off_renewal_plan_id) unless cat_age_off_renewal_plan_id.blank?
  end

  # has_one renewal_plan
  def renewal_plan=(new_renewal_plan)
    if new_renewal_plan.nil?
      self.renewal_plan_id = nil
    else
      raise ArgumentError.new("expected Plan ") unless new_renewal_plan.is_a? Plan
      self.renewal_plan_id = new_renewal_plan._id
      @renewal_plan = new_renewal_plan
    end
  end

  def renewal_plan(date = nil)
    return @renewal_plan if defined? @renewal_plan

    if date.present? && renewal_plan_mappings.by_date(date).present?
      renewal_mapping = renewal_plan_mappings.by_date(date).first
      @renewal_plan = renewal_mapping.renewal_plan
    else
      @renewal_plan = Plan.find(renewal_plan_id) unless renewal_plan_id.blank?
    end
  end

  def minimum_age
    if premium_tables.any?
      premium_tables.min(:age)
    else
      read_attribute(:minimum_age)
    end
  end

  def bound_age(given_age)
    return minimum_age if given_age < minimum_age
    return maximum_age if given_age > maximum_age
    given_age
  end

  def premium_table_for(schedule_date)
    self.premium_tables.select do |pt|
      (pt.start_on <= schedule_date) && (pt.end_on >= schedule_date)
    end
  end

  def premium_for(schedule_date, age)
    bound_age_val = bound_age(age)
    begin
      value = premium_table_for(schedule_date).detect {|pt| pt.age == bound_age_val }.cost
      BigDecimal(value.to_s).round(2).to_f
    rescue
      raise [self.id, bound_age_val, schedule_date, age].inspect
    end
  end

  def dental?
    coverage_kind && coverage_kind.downcase == "dental"
  end

  def health?
    coverage_kind && coverage_kind.downcase == "health"
  end

  def is_dental_only?
    dental?
  end

  def can_use_aptc?
    metal_level != 'catastrophic'
  end

  def hsa_eligibility
    qhp = Products::Qhp.where(standard_component_id: hios_base_id, active_year: active_year).last
    return false unless qhp
    case qhp.hsa_eligibility.downcase
    when "" # dental always has empty data for hsa_eligibility in serff templates.
      return false
    when "yes"
      return true
    when "no"
      return false
    end
  end

  def ehb
    percent = read_attribute(:ehb)
    (percent && percent > 0) ? percent : 1
  end

  def is_csr?
    (EligibilityDetermination::CSR_KIND_TO_PLAN_VARIANT_MAP.values - [EligibilityDetermination::CSR_KIND_TO_PLAN_VARIANT_MAP.default]).include? csr_variant_id
  end

  def deductible_integer
    (deductible && deductible.gsub(/\$/,'').gsub(/,/,'').to_i) || nil
  end

  def plan_deductible
    deductible_integer
  end

  def hsa_plan?
    name = self.name
    regex = name.match("HSA")
    if regex.present?
      return true
    else
      return false
    end
  end

  def plan_hsa
    name = self.name
    regex = name.match("HSA")
    regex.present? ? 'Yes': 'No'
  end

  def renewal_plan_type
    hios = self.hios_base_id
    kp = ["94506DC0390001","94506DC0390002","94506DC0390003","94506DC0390004","94506DC0390005","94506DC0390006","94506DC0390007","94506DC0390008","94506DC0390009","94506DC0390010","94506DC0390011"]
    cf_nonhsa = ["78079DC0160001","78079DC0160002","86052DC0400003"]
    cf_reg = ["86052DC0400001","86052DC0400002","86052DC0400004","86052DC0400007","86052DC0400008","78079DC0210001","78079DC0210002","78079DC0210003","78079DC0210004"]
    cf_hsa = ["86052DC0400005","86052DC0400006","86052DC0400009"]
    return "2017 Plan" if self.active_year != 2016
    if kp.include?(hios)
      return "KP"
    elsif cf_nonhsa.include?(hios)
      return "CFNONHSA"
    elsif cf_reg.include?(hios)
      return "CFREG"
    elsif cf_hsa.include?(hios)
      return "CFHSA"
    end
  end

  class << self

    def has_rates_for_all_carriers?(start_on_date=nil)
      date = start_on_date || PlanYear.calculate_start_on_dates[0]
      return false if date.blank?

      Rails.cache.fetch("#{date.to_s}", expires_in: 2.days) do
        Plan.collection.aggregate([
          {"$match" => {"active_year" => date.year}},
          {"$match" => {"coverage_kind" => "health"}},
          {"$unwind" => '$premium_tables'},
          {"$match" => {"premium_tables.start_on" => { "$lte" => date}}},
          {"$match" => {"premium_tables.end_on" => { "$gte" => date}}},
        ],:allow_disk_use => true).to_a.present?
      end
    end

    def monthly_premium(plan_year, hios_id, insured_age, coverage_begin_date)
      result = []
      if plan_year.to_s == coverage_begin_date.to_date.year.to_s
        [insured_age].flatten.each do |age|
          cost = Plan.find_by(active_year: plan_year, hios_id: hios_id)
          .premium_tables.where(:age => age, :start_on.lte => coverage_begin_date, :end_on.gte => coverage_begin_date)
          .entries.first.cost
          result << { age: age, cost: cost }
        end
      end
      result
    end

    def open_enrollment_year
      Organization.open_enrollment_year
    end

    def valid_shop_health_plans(type="carrier", key=nil, year_of_plans=Plan.open_enrollment_year)
      Rails.cache.fetch("plans-#{Plan.count}-for-#{key.to_s}-at-#{year_of_plans}-ofkind-health", expires_in: 5.hour) do
        Plan.public_send("valid_shop_by_#{type}_and_year", key.to_s, year_of_plans).where({coverage_kind: "health"}).to_a
      end
    end

    def valid_shop_health_plans_for_service_area(type="carrier", key=nil, year_of_plans=Plan.open_enrollment_year, carrier_service_area_pairs=[])
      Plan.for_service_areas_and_carriers(carrier_service_area_pairs, year_of_plans)
    end

    def valid_for_carrier(active_year)
      # carrier_ids = Plan.shop_dental_by_active_year(active_year).map(&:carrier_profile_id).uniq
      # carrier_ids.map{|c| org= Organization.where(:'carrier_profile._id' => c).first;org}
      Plan.shop_dental_by_active_year(active_year).map(&:carrier_profile).uniq
    end

    def valid_shop_dental_plans(type="carrier", key=nil, year_of_plans=Plan.open_enrollment_year)
      Rails.cache.fetch("dental-plans-#{Plan.count}-for-#{key.to_s}-at-#{year_of_plans}", expires_in: 5.hour) do
        Plan.public_send("shop_dental_by_active_year", year_of_plans).to_a
      end
    end

    def reference_plan_metal_level_for_options
      REFERENCE_PLAN_METAL_LEVELS.map{|k| [k.humanize, k]}
    end

    def individual_plans(coverage_kind:, active_year:, tax_household:, hbx_enrollment:)
      case coverage_kind
      when 'dental'
        Plan.individual_dental_by_active_year(active_year).with_premium_tables
      when 'health'
        shopping_family_member_ids = hbx_enrollment.hbx_enrollment_members.map(&:applicant_id) rescue nil
        # picks csr_kind based on individual level
        csr_kind = tax_household&.eligibile_csr_kind(shopping_family_member_ids)
        if csr_kind.present?
          Plan.individual_health_by_active_year_and_csr_kind_with_catastrophic(active_year, csr_kind).with_premium_tables
        else
          Plan.individual_health_by_active_year_and_csr_kind_with_catastrophic(active_year).with_premium_tables
        end
      end
    end

    def shop_plans coverage_kind, year
      if coverage_kind == 'health'
        shop_health_plans year
      else
        shop_dental_plans year
      end
    end

    def search_options(plans)
      options ={
        'plan_type': [],
        'plan_hsa': [],
        'metal_level': [],
        'plan_deductible': []
      }
      options.each do |option, value|
        collected = plans.collect { |plan|
          if option == :metal_level
            MetalLevel.new(plan.send(option))
          else
            plan.send(option)
          end
        }.uniq.sort
        unless collected.none?
          options[option] = collected
        end
      end
      options
    end

    def shop_health_plans year
      $shop_plan_cache = {} unless defined? $shop_plan_cache
      if $shop_plan_cache[year].nil?
        $shop_plan_cache[year] =
          Plan::REFERENCE_PLAN_METAL_LEVELS.map do |metal_level|
            Plan.valid_shop_health_plans('metal_level', metal_level, year)
        end.flatten
      end
      $shop_plan_cache[year]
    end

    def shop_dental_plans year
      shop_dental_by_active_year year
    end

    def build_plan_selectors market_kind, coverage_kind, year
      plans = shop_plans coverage_kind, year
      selectors = {}
      if coverage_kind == 'dental'
        selectors[:dental_levels] = plans.map{|p| p.dental_level}.uniq.unshift('any')
      else
        selectors[:metals] = plans.map{|p| p.metal_level}.uniq.unshift('any')
      end
      selectors[:carriers] = plans.map{|p|
        id = p.carrier_profile_id
        carrier_profile = CarrierProfile.find(id)
        [ carrier_profile.legal_name, carrier_profile.abbrev, carrier_profile.id ]
        }.uniq.unshift(['any','any'])
      selectors[:plan_types] =  plans.map{|p| p.plan_type}.uniq.unshift('any')
      # TODO: Refactor this to in_state_network oor something
      selectors[:dc_network] =  ['any', 'true', 'false']
      selectors[:nationwide] =  ['any', 'true', 'false']
      selectors
    end

    def build_plan_features market_kind, coverage_kind, year
      plans = shop_plans coverage_kind, year
      feature_array = []
      plans.each{|plan|

        characteristics = {}
        characteristics['plan_id'] = plan.id.to_s
        if coverage_kind == 'dental'
          characteristics['dental_level'] = plan.dental_level
        else
          characteristics['metal'] = plan.metal_level
        end
        characteristics['carrier'] = plan.carrier_profile.organization.legal_name
        characteristics['plan_type'] = plan.plan_type
        characteristics['deductible'] = plan.deductible_integer
        characteristics['carrier_abbrev'] = plan.carrier_profile.abbrev
        characteristics['nationwide'] = plan.nationwide
        characteristics['dc_in_network'] = plan.dc_in_network

        if plan.deductible_integer.present?
          feature_array << characteristics
        else
          Rails.logger.error("ERROR: No deductible found for Plan: #{p.try(:name)}, ID: #{plan.id}")
        end
      }
      feature_array
    end
  end
end

class MetalLevel
  include Comparable
  attr_reader :name
  METAL_LEVEL_ORDER = %w(BRONZE SILVER GOLD PLATINUM)
  def initialize(name)
    @name = name
  end

  def to_s
    @name
  end

  def <=>(metal_level)
    metal_level = safe_assign(metal_level)
    my_level = self.name.upcase
    compared_level = metal_level.name.upcase
    METAL_LEVEL_ORDER.index(my_level) <=> METAL_LEVEL_ORDER.index(compared_level)
  end

  def eql?(metal_level)
    metal_level = safe_assign(metal_level)
    METAL_LEVEL_ORDER.index(self.name) ==  METAL_LEVEL_ORDER.index(metal_level.name)
  end

  def hash
    @name.hash
  end

  private

  def safe_assign(metal_level)
    if metal_level.is_a? String
      metal_level = MetalLevel.new(metal_level)
    end
    metal_level
  end
end
