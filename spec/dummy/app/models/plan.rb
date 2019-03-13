class Plan
  include Mongoid::Document
  include Mongoid::Timestamps

  COVERAGE_KINDS = %w[health dental]
  METAL_LEVEL_KINDS = %w[bronze silver gold platinum catastrophic dental]
  REFERENCE_PLAN_METAL_LEVELS = %w[bronze silver gold platinum]
  MARKET_KINDS = %w(shop individual)
  INDIVIDUAL_MARKET_KINDS = %w(individual coverall)
  PLAN_TYPE_KINDS = %w[pos hmo epo ppo indemnity]
  DENTAL_METAL_LEVEL_KINDS = %w[high low]


  field :hbx_id, type: Integer
  field :active_year, type: Integer
  field :market, type: String
  field :coverage_kind, type: String
  field :carrier_profile_id, type: BSON::ObjectId
  field :metal_level, type: String

  field :hios_id, type: String
  field :hios_base_id, type: String
  field :csr_variant_id, type: String

  field :name, type: String
  field :abbrev, type: String
  field :provider, type: String
  field :ehb, type: Float, default: 0.0

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

  # More Attributes from qhp
  field :plan_type, type: String  # "POS", "HMO", "EPO", "PPO"
  field :deductible, type: String # Deductible
  field :family_deductible, type: String

  field :nationwide, type: Boolean # Nationwide
  field :dc_in_network, type: Boolean # DC In-Network or not

  # Fields for provider direcotry and rx formulary url
  field :provider_directory_url, type: String
  field :rx_formulary_url, type: String

  # for dental plans only, metal level -> high/low values
  field :dental_level, type: String


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