class Plan
  include Mongoid::Document
  include Mongoid::Timestamps
#  include Mongoid::Versioning

  COVERAGE_KINDS = %w[health dental]
  METAL_LEVEL_KINDS = %w[bronze silver gold platinum catastrophic dental]
  MARKET_KINDS = %w(shop individual)


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

  embeds_many :premium_tables
  accepts_nested_attributes_for :premium_tables

  index({ hbx_id: 1 })
  index({ coverage_kind: 1 })
  index({ metal_level: 1 })
  index({ market: 1 })

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

  # Marketplace
  scope :shop_market,          ->{ where(market: "shop") }
  scope :individual_market,    ->{ where(market: "individual") }

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
    end
    self.carrier_profile
  end

  def carrier_profile
    CarrierProfile.find(carrier_profile_id) unless carrier_profile_id.blank?
  end

  # has_one renewal_plan
  def renewal_plan=(new_renewal_plan)
    if renewal_plan.nil?
      self.renewal_plan_id = nil
    else
      raise ArgumentError.new("expected Plan ") unless renewal_plan.is_a? Plan
      self.renewal_plan_id = renewal_plan._id
    end
    self.renewal_plan
  end

  def renewal_plan
    find(renewal_plan_id) unless renewal_plan_id.blank?
  end


  def bound_age(given_age)
    return minimum_age if given_age < minimum_age
    return maximum_age if given_age > maximum_age
    given_age
  end

  def reload_premium_cache
    self.premium_tables.each do |premium|
      cache_key = [hios_id, active_year, premium.age].join('-')
      #Rails.cache.write(cache_key, premium.cost)
      $redis.set(cache_key, premium.cost)
    end
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

    def fetch_monthly_premium(plan_year, hios_id, insured_age, coverage_begin_date)
      begin_date = Date.parse(coverage_begin_date)
      plan_documents = Plan.and({ active_year: plan_year }, { hios_id: hios_id }).entries
      premium_table = plan_documents.first.premium_tables.detect do |table|
        (table.age == insured_age) && (begin_date >= table.start_on) && (begin_date <= table.end_on)
      end

      if cost = premium_table.cost
        cache_key = [hios_id, plan_year, insured_age].join('-')
        $redis.set(cache_key, cost)
      else
        nil
      end
    end
    
    def redis_monthly_premium(plan_year, hios_id, insured_age, coverage_begin_date)
      result = []
      if plan_year.to_s == coverage_begin_date.to_date.year.to_s
        [insured_age].flatten.each do |age|
          cache_key = [hios_id, plan_year, age].join('-')
          cost = $redis.get(cache_key)
          if cost.blank?
            cost = fetch_monthly_premium(plan_year, hios_id, age, coverage_begin_date)
          end
          result << { age: age, cost: cost.try(:to_f) }
        end
      end
      result
    rescue => e
      Rails.logger.error { e.message }
      []
    end
  end
end
