module BenefitMarkets
  module Products
    class DentalProducts::DentalProduct < BenefitMarkets::Products::Product

      PRODUCT_PACKAGE_KINDS = [:single_product, :multi_product, :single_issuer]
      METAL_LEVEL_KINDS     = [:dental]

      field :hios_id,                     type: String
      field :hios_base_id,                type: String
      field :csr_variant_id,              type: String
      field :dental_level,                type: Symbol
      field :dental_plan_kind,            type: Symbol

      field :hsa_eligibility,             type: Boolean,  default: false
      field :is_standard_plan,            type: Boolean,  default: false
      field :is_hc4cc_plan,               type: Boolean,  default: false

      field :metal_level_kind,            type: Symbol
      field :ehb,                         type: Float,    default: 0.0

      # The ehb_premium for SecondLowestDentalProduct is members_premium * ehb_apportionment_for_pediatric_dental.
      # Ehb Apportionment For Pediatric Dental.
      field :ehb_apportionment_for_pediatric_dental, type: Float

      belongs_to  :renewal_product,
                  inverse_of: nil,
                  class_name: "BenefitMarkets::Products::DentalProducts::DentalProduct",
                  optional: true
  

      validates :metal_level_kind,
                presence: true,
                inclusion: {in: METAL_LEVEL_KINDS, message: "%{value} is not a valid metal level kind"}

      index(
        {
          "service_area_id" => 1,
          "application_period.min" => 1,
          "application_period.max" => 1,
          "benefit_market_kind" => 1,
          "premium_tables.rating_area_id" => 1,
          "premium_tables.effective_period.min" => 1,
          "premium_tables.effective_period.max" => 1
        },
        {
          name: "dental_products_premium_tables_for_benchmark_premiums_search_index"
        }
      )

      scope :hc4cc_plans,         ->{ where(is_hc4cc_plan: true) }


      alias_method :is_standard_plan?, :is_standard_plan

      def metal_level
        dental_level.to_s
      end

      def product_type
        dental_plan_kind.to_s
      end

    end
  end
end
