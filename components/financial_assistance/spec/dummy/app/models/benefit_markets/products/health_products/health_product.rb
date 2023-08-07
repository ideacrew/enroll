# frozen_string_literal: true

module BenefitMarkets
  module Products
    module HealthProducts
      # dummy HealthProduct spec that inherits Product class
      class HealthProduct < BenefitMarkets::Products::Product

        VARIANTS_SPECIFIC_TO_SILVER = %w[04 05 06].freeze

        PRODUCT_PACKAGE_KINDS = [:single_issuer, :metal_level, :single_product].freeze  #shop by default
        CONGRESSIONAL_PRODUCT_PACKAGE_KINDS = [:metal_level].freeze
        METAL_LEVEL_KINDS = [:bronze, :silver, :gold, :platinum, :catastrophic].freeze

        HEALTH_PLAN_MAP = {
          hmo: "Health Maintenance Organization", # designated primary care physician (PCP) who's
          #   referral is required for specialists who are in-network
          ppo: "Preferred provider Organization", # health plan with a 'preferred' network of providers
          #   in an area
          pos: "Point of Service",                # hmo/ppo hybrid. PCP referral for specialist required.
          #   In-network providers are lower cost, may access out-of-network
          #   providers at higher cost
          epo: "Exclusive Provider Network"      # hmo/ppo hybrid. PCP referral for specialist not required, but
          #   must pay out-of-pocket for doctors outside network
        }.freeze


        field :hios_id,                     type: String
        field :hios_base_id,                type: String
        field :csr_variant_id,              type: String

        field :health_plan_kind,            type: Symbol  # => :hmo, :ppo, :pos, :epo
        field :metal_level_kind,            type: Symbol

      # Essential Health Benefit (EHB) percentage
        field :ehb,                         type: Float,    default: 0.0
        field :is_standard_plan,            type: Boolean,  default: false
        field :is_hc4cc_plan,               type: Boolean,  default: false

        field :rx_formulary_url,            type: String
        field :hsa_eligibility,             type: Boolean,  default: false
        field :network_information,         type: String

        index({ hios_id: 1, "active_period.min": 1, "active_period.max": 1, name: 1 }, {name: "products_health_product_hios_active_period_name_index"})
        index({ "active_period.min": 1, "active_period.max": 1, market: 1, coverage_kind: 1, nationwide: 1, name: 1 }, {name: "health_products_a_period_market_c_kind_nationwide_name_index"})
        index({ csr_variant_id: 1}, {sparse: true, name: "product_health_products_csr_variant_index"})

        index(
          {
            "metal_level_kind" => 1,
            "csr_variant_id" => 1,
            "service_area_id" => 1,
            "application_period.min" => 1,
            "application_period.max" => 1,
            "benefit_market_kind" => 1,
            "premium_tables.rating_area_id" => 1,
            "premium_tables.effective_period.min" => 1,
            "premium_tables.effective_period.max" => 1
          },
          {
            name: "health_products_premium_tables_for_benchmark_premiums_search_index"
          }
        )

        scope :standard_plans,      ->{ where(is_standard_plan: true) }
        scope :hc4cc_plans,         ->{ where(is_hc4cc_plan: true) }

        scope :ppo_plans,           ->{ where(health_plan_kind: :ppo) }
        scope :pos_plans,           ->{ where(health_plan_kind: :pos) }
        scope :hmo_plans,           ->{ where(health_plan_kind: :hmo) }
        scope :epo_plans,           ->{ where(health_plan_kind: :epo) }

        scope :bronze_plans,        ->{ where(metal_level_kind: :bronze) }
        scope :silver_plans,        ->{ where(metal_level_kind: :silver) }
        scope :gold_plans,          ->{ where(metal_level_kind: :gold) }
        scope :platinum_plans,      ->{ where(metal_level_kind: :platinum) }
        scope :catastrophic_plans,  ->{ where(metal_level_kind: :catastrophic) }
      end
    end
  end
end
