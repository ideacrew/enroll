module BenefitMarkets
  module Products
    module ProductPackages
      class ProductPackageFactory
        attr_reader :benefit_option_kind

        def initialize(bo_kind)
          @benefit_option_kind = bo_kind
        end

        def available_pricing_models
          ::BenefitMarkets::PricingModels::PricingModel.where({})
        end

        def available_contribution_models
          ::BenefitMarkets::ContributionModels::ContributionModel.where({})
        end

        def allowed_benefit_option_kinds
          ::BenefitMarkets::Products::ProductPackages::ProductPackage::BENEFIT_OPTION_KINDS.map(&:to_s)
        end

        def select_model_subclass
          ::BenefitMarkets::Products::ProductPackages::ProductPackage.subclass_for(benefit_option_kind)
        end

        def build_shared_params(benefit_catalog_id, title, contribution_model_id, pricing_model_id, product_year)
          {
            benefit_catalog_id: benefit_catalog_id,
            title: title,
            contribution_model_id: contribution_model_id,
            pricing_model_id: pricing_model_id,
            product_year: product_year
          }
        end

        def build_product_package(benefit_catalog_id, title, contribution_model_id, pricing_model_id, product_year)
          select_model_subclass.new(
            build_shared_params(benefit_catalog_id, title, contribution_model_id, pricing_model_id, product_year)
          )
        end

        def build_issuer_product_package(benefit_catalog_id, title, contribution_model_id, pricing_model_id, product_year, issuer_id)
          select_model_subclass.new(
            build_shared_params(benefit_catalog_id, title, contribution_model_id, pricing_model_id, product_year).merge({
              issuer_id: issuer_id
            })
          )
        end

        def build_metal_level_product_package(benefit_catalog_id, title, contribution_model_id, pricing_model_id, product_year, metal_level)
          select_model_subclass.new(
            build_shared_params(benefit_catalog_id, title, contribution_model_id, pricing_model_id, product_year).merge({
              metal_level: metal_level
            })
          )
        end
      end
    end
  end
end
