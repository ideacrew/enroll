class Plan
  include Mongoid::Document
  include Mongoid::Timestamps
#  include Mongoid::Versioning

  COVERAGE_KINDS = %w[health dental]
  METAL_LEVEL_KINDS = %w[bronze silver gold platinum catastrophic dental]
  MARKET_KINDS = %w(shop individual)


  field :ehb, type: Float, default: 0.0
  field :hbx_id, type: String
  field :name, type: String
  field :abbrev, type: String

  field :coverage_kind, type: String
  field :metal_level, type: String
  field :market, type: String

  field :carrier_profile_id, type: BSON::ObjectId
  field :active_year, type: Integer
  field :hios_id, type: String
  field :minimum_age, type: Integer, default: 0
  field :maximum_age, type: Integer, default: 120

  field :renewal_plan_id, type: BSON::ObjectId

  embeds_many :premium_tables
  accepts_nested_attributes_for :premium_tables

  field :is_active, type: Boolean, default: true
  field :updated_by, type: String


  index({ hbx_id: 1 })
  index({ coverage_kind: 1 })
  index({ metal_level: 1 })
  index({ market: 1 })

  index({ carrier_profile_id: 1 })
  index({ active_year: 1, hios_id: 1}, {unique: true})
  index({ renewal_plan_id: 1 })

  validates_presence_of :name, :carrier_profile_id, :hios_id

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
             
  validates :active_year,
    length: { minimum: 4, maximum: 4, message: "active year must be four digits" },
    numericality: { greater_than: 2013, less_than: 2020, message: "active year must fall between 2014..2019" },
    allow_blank: false
  
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


end
