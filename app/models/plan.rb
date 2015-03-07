class Plan
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Versioning

  Premium = Struct.new(:age, :cost_in_cents, :start_on, :end_on)

  COVERAGE_KINDS = %w[health dental]
  METAL_LEVEL_KINDS = %w[bronze silver gold platinum catastrophic]


  field :hbx_id, type: String
  field :name, type: String
  field :abbrev, type: String

  field :coverage_kind, type: String
  field :metal_level, type: String

  field :carrier_profile_id, type: BSON::ObjectId
  field :active_year, type: Integer
  field :hios_id, type: String

  field :ehb_pct_as_int, type: Integer
  field :renewal_plan_id, type: BSON::ObjectId

  field :premiums, type: Array, default: []

  index({ hbx_id: 1 })
  index({ coverage_type: 1 })
  index({ metal_level: 1 })
  index({ market_type: 1 })

  index({ carrier_id: 1 })
  index({ active_year: 1, hios_id: 1}, {unique: true})
  index({ renewal_plan_id: 1 })

  validates_presence_of :name, :coverage_type, :metal_level, :carrier_id, :active_year, :hios_id,
                        :ehb_pct_as_int

  validates :coverage_kind,
   allow_blank: false,
   inclusion: { 
     in: COVERAGE_KINDS, 
     message: "%{value} is not a valid coverage kind" 
  }
             
  validates :metal_level_kind,
   allow_blank: false,
   inclusion: { 
     in: METAL_LEVEL_KINDS, 
     message: "%{value} is not a valid metal level kind" 
  }
             
  validates :active_year,
    length: { minimum: 4, maximum: 4, message: "active year must be four digits" },
    numericality: { greater_than: 2013, less_than: 2020, message: "active year must fall between 2014..2019" },
    allow_blank: false
  
  validates :ehb_pct_as_int,
    length: { minimum: 1, maximum: 3, message: "EHB percent must be between 0 and 100" },
    numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100, message: "ehb percent must fall between 1..100" },
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
