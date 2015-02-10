class Carrier
  include Mongoid::Document
  include Mongoid::Timestamps

  auto_increment :hbx_id, :seed => 999
  field :carrier_plan_id, type: String # internal ID for carrier

  field :name, type: String
  field :fein, type: String
  field :abbrev, as: :abbreviation, type: String
  field :ind_hlt, as: :individual_market_health, type: Boolean, default: false
  field :ind_dtl, as: :individual_market_dental, type: Boolean, default: false
  field :shp_hlt, as: :shop_market_health, type: Boolean, default: false
  field :shp_dtl, as: :shop_market_dental, type: Boolean, default: false
  field :is_active, type: Boolean, default: true

  has_many :policies, counter_cache: true, index: true

  embeds_many :plans

  index({name: 1})
  index({hbx_carrier_id: 1})
  index({fein: 1})

  index({ "plans.name" => 1 })
  index({ "plans.hbx_id" => 1 })
  index({ "plans.coverage_type" => 1 })
  index({ "plans.metal_level" => 1 })
  index({ "plans.market_type" => 1 })
  index({ "plans.year" => 1 })
  index({ "plans.hios_plan_id" => 1 })
  index({ "plans.year" => 1 }, "plans.hios_plan_id" => 1 })
  index({ "plans.premium_tables.quarter" => 1 })
  index({ "plans.premium_tables.age" => 1 })

  scope :by_name, order_by(name: 1)

  def self.individual_market_health
    where(individual_market_health: true)
  end

  def self.individual_market_dental
    where(individual_market_dental: true)
  end

  def self.shop_market_health
    where(shop_market_health: true)
  end

  def self.shop_market_dental
    where(shop_market_dental: true)
  end

 end

