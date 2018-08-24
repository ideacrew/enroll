module BenefitMarkets
  module Products
    class DentalProducts::DentalProduct < BenefitMarkets::Products::Product

      PRODUCT_PACKAGE_KINDS = [:single_product, :multi_product]
      METAL_LEVEL_KINDS     = [:dental]

      field :hios_id,                     type: String
      field :hios_base_id,                type: String
      field :csr_variant_id,              type: String
      field :dental_level,                type: String
      field :dental_plan_kind,            type: Symbol

      field :hsa_eligibility,             type: Boolean,  default: false

      field :metal_level_kind,            type: Symbol
      field :ehb,                         type: Symbol

      belongs_to  :renewal_product,
                  inverse_of: nil,
                  class_name: "BenefitMarkets::Products::DentalProducts::DentalProduct"

      validates :metal_level_kind,
                presence: true,
                inclusion: {in: METAL_LEVEL_KINDS, message: "%{value} is not a valid metal level kind"}

      def metal_level
        metal_level_kind.to_s
      end

    end
  end
end
