module BenefitMarkets
  module Products
    module HealthProducts
      class MetalLevelHealthProductPackageForm < ::BenefitMarkets::Product::ProductPackageForm
        attr_accessor :metal_level

        validates_presence_of :metal_level, :allow_blank => false

        def build_object_using_factory
          product_package_factory.build_metal_level_product_package(
            benefit_catalog_id,
            title,
            contribution_model_id,
            pricing_model_id,
            product_year,
            metal_level
          )
        end

        def has_additional_attributes?
          true
        end

        def additional_form_fields_partial
          "metal_level_health_additional_form_fields"
        end
      end

    end
  end
end
