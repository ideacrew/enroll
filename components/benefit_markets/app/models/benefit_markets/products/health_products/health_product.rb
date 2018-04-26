module BenefitMarkets
  module Products
    class HealthProducts::HealthProduct < ::BenefitMarket::Products::Product

      METAL_LEVEL_KINDS = [:bronze, :silver, :gold, :platinum, :catastrophic]

      PLAN_KIND_MAP = {
          hmo: "Health Maintenance Organization", # designated primary care physician (PCP) who's 
                                                  #   referral is required for specialists who are in-network
          ppo: "Preferred provider Organization", # health plan with a “preferred” network of providers 
                                                  #   in an area
          pos: "Point of Service",                # hmo/ppo hybrid. PCP referral for specialist required. 
                                                  #   In-network providers are lower cost, may access out-of-network 
                                                  #   providers at higher cost
          epo: "Exclusive Provider Network",      # hmo/ppo hybrid. PCP referral for specialist not required, but 
                                                  #   must pay out-of-pocket for doctors outside network
        }


      field :effective_period,        type: Range
      field :hios_id,                 type: String
      field :hios_base_id,            type: String
      field :csr_variant_id,          type: String

      field :plan_kind,               type: Symbol  # => :hmo, :ppo, :pos, :epo
      field :ehb,                     type: Float,    default: 0.0
      field :is_standard_plan,        type: Boolean,  default: false

      field :provider_directory_url,  type: String
      field :rx_formulary_url,        type: String


      has_one     :renewal_health_product,
                  inverse_of: nil,
                  class_name: "BenefitMarkets::Products::HealthProducts::HealthProduct"

      has_one     :cat_age_off_health_product,
                  inverse_of: nil,
                  class_name: "BenefitMarkets::Products::HealthProducts::HealthProduct"

      embeds_one  :sbc_document,  
                  as: :documentable,
                  :class_name => "::Document"

      has_one     :service_area,
                  class_name: "BenefitMarkets::Locations::ServiceArea"
      has_many    :rating_areas,
                  class_name: "BenefitMarkets::Locations::RatingArea"


      index({ hios_id: 1, "active_period.min": 1, "active_period.max": 1, name: 1 })
      index({ "active_period.min": 1, "active_period.max": 1, market: 1, coverage_kind: 1, nationwide: 1, name: 1 })
      index({ csr_variant_id: 1}, {sparse: true})

      validates :plan_kind,
                presence: true,
                inclusion: {in: PLAN_KIND_MAP.keys, message: "%{value} is not a valid product kind"}

      validates :metal_level,
                presence: true,
                inclusion: {in: METAL_LEVEL_KINDS, message: "%{value} is not a valid metal level kind"}


      alias_method :is_standard_plan, :is_standard_plan?

    end
  end
end
