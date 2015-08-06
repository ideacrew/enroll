class Plan
  include Mongoid::Document
  include Mongoid::Timestamps
#  include Mongoid::Versioning

  COVERAGE_KINDS = %w[health dental]
  METAL_LEVEL_KINDS = %w[bronze silver gold platinum catastrophic dental]
  REFERENCE_PLAN_METAL_LEVELS = %w[bronze silver gold platinum]
  MARKET_KINDS = %w(shop individual)
  PLAN_TYPE_KINDS = %w[pos hmo epo ppo]


  field :hbx_id, type: Integer
  field :active_year, type: Integer
  field :hios_id, type: String
  field :name, type: String
  field :abbrev, type: String
  field :provider, type: String
  field :ehb, type: Float, default: 0.0

  field :coverage_kind, type: String
  field :metal_level, type: String
  field :market, type: String

  field :carrier_profile_id, type: BSON::ObjectId
  field :renewal_plan_id, type: BSON::ObjectId

  field :minimum_age, type: Integer, default: 0
  field :maximum_age, type: Integer, default: 120

  field :is_active, type: Boolean, default: true
  field :updated_by, type: String
  field :sbc_file, type: String

  embeds_many :premium_tables
  accepts_nested_attributes_for :premium_tables

  # More Attributes from qhp
  field :plan_type, type: String  # "POS", "HMO", "EPO", "PPO"
  field :deductible, type: String # Deductible
  field :family_deductible, type: String
  field :nationwide, type: Boolean # Nationwide
  field :out_of_service_area_coverage, type: Boolean # DC In-Network or not

  default_scope -> {order("name ASC")}

  index({ hbx_id: 1 })
  index({ coverage_kind: 1 })
  index({ metal_level: 1 })
  index({ market: 1 })
  index({ active_year: 1 })

  index({ active_year: 1,  market: 1, coverage_kind: 1, metal_level: 1 })
  index({ active_year: 1,  market: 1, coverage_kind: 1, metal_level: 1, carrier_profile_id: 1 })

  index({ carrier_profile_id: 1 })
  index({ active_year: 1, hios_id: 1}, {unique: true})
  index({ renewal_plan_id: 1 })

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

  validates :market,
   allow_blank: false,
   inclusion: {
     in: MARKET_KINDS,
     message: "%{value} is not a valid market"
   }

  validates_inclusion_of :active_year,
    in: 2014..(Date.today.year + 3),
    message: "%{value} is an invalid active year"

  ## Scopes
  # Metal level
  scope :platinum_level,      ->{ where(metal_level: "platinum") }
  scope :gold_level,          ->{ where(metal_level: "gold") }
  scope :silver_level,        ->{ where(metal_level: "silver") }
  scope :bronze_level,        ->{ where(metal_level: "bronze") }
  scope :catastrophic_level,  ->{ where(metal_level: "catastrophic") }

  # Plan Type
  scope :ppo_plan, ->{ where(plan_type: "ppo") }
  scope :pos_plan, ->{ where(plan_type: "pos") }
  scope :hmo_plan, ->{ where(plan_type: "hmo") }
  scope :epo_plan, ->{ where(plan_type: "epo") }

  # Nationwide ?
  scope :nationwide, ->{ where(nationwide: "true") }

  # DC In-Network ?
  scope :dc_in_network, ->{ where(out_of_service_area_coverage: "false") }

  # Marketplace
  scope :shop_market,          ->{ where(market: "shop") }
  scope :individual_market,    ->{ where(market: "individual") }

  scope :by_active_year, -> {where(active_year: TimeKeeper.date_of_record.year)}

  scope :valid_shop_by_carrier, ->(carrier_profile_id) {where(carrier_profile_id: carrier_profile_id, active_year: TimeKeeper.date_of_record.year, market: "shop", coverage_kind: "health", metal_level: {"$in" => ::Plan::REFERENCE_PLAN_METAL_LEVELS})}
  scope :valid_shop_by_metal_level, ->(metal_level) {where(active_year: TimeKeeper.date_of_record.year, market: "shop", coverage_kind: "health", metal_level: metal_level)}

  # Carriers: use class method (which may be chained)
  def self.find_by_carrier_profile(carrier_profile)
    where(carrier_profile_id: carrier_profile._id)
  end

  # scope :named, ->(name){ where(name: name) }
  # where(carrier_profile_id: carrier_profile._id)


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

  def renewal_plan
    return @renewal_plan if defined? @renewal_plan
    @renewal_plan = find(renewal_plan_id) unless renewal_plan_id.blank?
  end


  def bound_age(given_age)
    return minimum_age if given_age < minimum_age
    return maximum_age if given_age > maximum_age
    given_age
  end

  def premium_for(schedule_date, age)
    bound_age_val = bound_age(age)
    begin
    self.premium_tables.detect do |pt|
      pt.age == bound_age_val &&
        (pt.start_on <= schedule_date) && (pt.end_on >= schedule_date)
    end.cost
    rescue
      raise [self.id, bound_age_val, schedule_date, age].inspect
    end
  end

  def is_dental_only?
    return false if self.coverage_kind.blank?
    self.coverage_kind.downcase == "dental"
  end

  class << self

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

    def valid_shop_health_plans(type="carrier", key=nil)
      Rails.cache.fetch("plans-#{Plan.count}-for-#{key.to_s}-at-#{TimeKeeper.date_of_record.year}", expires_in: 5.hour) do
        Plan.public_send("valid_shop_by_#{type}", key.to_s).to_a
      end
    end

    def reference_plan_metal_level_for_options
      REFERENCE_PLAN_METAL_LEVELS.map{|k| [k.humanize, k]}
    end
  end
end
