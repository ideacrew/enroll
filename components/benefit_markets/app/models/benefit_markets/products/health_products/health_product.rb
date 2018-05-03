module BenefitMarkets
  module Products
    module HealthProducts
      class HealthProduct < BenefitMarkets::Products::Product

        METAL_LEVEL_KINDS = [:bronze, :silver, :gold, :platinum, :catastrophic]

        HEALTH_PLAN_KIND_MAP = {
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


        field :hios_id,                     type: String
        field :hios_base_id,                type: String
        field :csr_variant_id,              type: String

        field :health_plan_kind,            type: Symbol  # => :hmo, :ppo, :pos, :epo
        field :metal_level_kind,            type: Symbol  

        # Essential Health Benefit (EHB) percentage
        field :ehb,                         type: Float,    default: 0.0
        field :is_standard_plan,            type: Boolean,  default: false
        field :is_reference_plan_eligible,  type: Boolean,  default: false

        field :provider_directory_url,      type: String
        field :rx_formulary_url,            type: String


        has_one     :health_product, as: :renewal_product,
                    inverse_of: nil,
                    class_name: "BenefitMarkets::Products::HealthProducts::HealthProduct"

        has_one     :health_product, as: :catastrophic_age_off_product,
                    inverse_of: nil,
                    class_name: "BenefitMarkets::Products::HealthProducts::HealthProduct"

        embeds_one  :sbc_document, as: :documentable,
                    :class_name => "::Document"


        validates_presence_of :hios_id, :health_plan_kind, :ehb

        validates_numericality_of :ehb, greater_than: 0.0, less_than: 1.0, allow_nil: false


        index({ hios_id: 1, "active_period.min": 1, "active_period.max": 1, name: 1 })
        index({ "active_period.min": 1, "active_period.max": 1, market: 1, coverage_kind: 1, nationwide: 1, name: 1 })
        index({ csr_variant_id: 1}, {sparse: true})

        scope :standard_plans,      ->{ where(is_standard_plan: true) }

        scope :ppo_plans,           ->{ where(health_plan_kind: :ppo) }
        scope :pos_plans,           ->{ where(health_plan_kind: :pos) }
        scope :hmo_plans,           ->{ where(health_plan_kind: :hmo) }
        scope :epo_plans,           ->{ where(health_plan_kind: :epo) }

        scope :bronze_plans,        ->{ where(metal_level: :bronze) }
        scope :silver_plans,        ->{ where(metal_level: :silver) }
        scope :gold_plans,          ->{ where(metal_level: :gold) }
        scope :platinum_plans,      ->{ where(metal_level: :platinum) }
        scope :catastrophic_plans,  ->{ where(metal_level: :catastrophic) }


        # TODO Create queries
        scope :premium_table_cover, ->(effective_date, rating_area){  }


        validates :health_plan_kind,
                  presence: true,
                  inclusion: {in: HEALTH_PLAN_KIND_MAP.keys, message: "%{value} is not a valid health product kind"}

        validates :metal_level_kind,
                  presence: true,
                  inclusion: {in: METAL_LEVEL_KINDS, message: "%{value} is not a valid metal level kind"}


        alias_method :is_standard_plan?, :is_standard_plan
        alias_method :is_reference_plan_eligible?, :is_reference_plan_eligible




      end
    end
  end
end
