class Plan
  include Mongoid::Document
  include Mongoid::Timestamps

  COVERAGE_KINDS = %w[health dental].freeze
  METAL_LEVEL_KINDS = %w[bronze silver gold platinum catastrophic dental].freeze
  REFERENCE_PLAN_METAL_LEVELS = %w[bronze silver gold platinum dental].freeze
  MARKET_KINDS = %w[shop individual].freeze
  PLAN_TYPE_KINDS = %w[pos hmo epo ppo].freeze
  DENTAL_METAL_LEVEL_KINDS = %w[high low].freeze


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

  field :plan_type, type: String  # "POS", "HMO", "EPO", "PPO"
  field :ehb, type: Float, default: 0.0

  field :minimum_age, type: Integer, default: 0
  field :maximum_age, type: Integer, default: 120

  field :deductible, type: String # Deductible
  field :family_deductible, type: String
  field :dental_level, type: String

  scope :by_active_year,        ->(active_year = TimeKeeper.date_of_record.year) { where(active_year: active_year) }
  scope :shop_market,           ->{ where(market: "shop") }
  scope :health_coverage,       ->{ where(coverage_kind: "health") }
  scope :dental_coverage,       ->{ where(coverage_kind: "dental") }

  embeds_many :premium_tables

  def dental?
    coverage_kind && coverage_kind.downcase == "dental"
  end

  def health?
    coverage_kind && coverage_kind.downcase == "health"
  end

  def is_dental_only?
    dental?
  end

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
end
