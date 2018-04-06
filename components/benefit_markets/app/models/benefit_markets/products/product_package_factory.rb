module BenefitMarkets
  module Products
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
        ::BenefitMarkets::Products::ProductPackage::BENEFIT_OPTION_KINDS.map(&:to_s)
      end

      def available_benefit_catalogs
        ::BenefitMarkets::BenefitMarketCatalog.where({})
      end

      def select_model_subclass
        ::BenefitMarkets::Products::ProductPackage.subclass_for(benefit_option_kind)
      end

      def build_shared_params(benefit_catalog_id, title, contribution_model_id, pricing_model_id)
        {
          benefit_catalog_id: benefit_catalog_id,
          title: title,
          contribution_model_id: contribution_model_id,
          pricing_model_id: pricing_model_id
        }
      end

      def build_product_package(benefit_catalog_id, title, contribution_model_id, pricing_model_id)
        select_model_subclass.new(
          build_shared_params(benefit_catalog_id, title, contribution_model_id, pricing_model_id)
        )
      end

      def build_issuer_product_package(benefit_catalog_id, title, contribution_model_id, pricing_model_id, issuer_id)
        select_model_subclass.new(
          build_shared_params(benefit_catalog_id, title, contribution_model_id, pricing_model_id).merge({
            issuer_id: issuer_id
          })
        )
      end

      def build_metal_level_product_package(benefit_catalog_id, title, contribution_model_id, pricing_model_id, metal_level)
        select_model_subclass.new(
          build_shared_params(benefit_catalog_id, title, contribution_model_id, pricing_model_id).merge({
            metal_level: metal_level
          })
        )
      end

      def persist(factory_object, e_reporter = nil)
        error_reporter = e_reporter.nil? ? factory_object : e_reporter
        return false unless validate(factory_object, error_reporter)
        factory_object.save.tap do |s_result|
          unless s_result
            factory_object.errors.each do |k, err|
              error_reporter.errors.add(k, err)
            end
          end
        end
      end

      protected

      def validate(product_package, error_reporter)
        [
          is_contribution_model_satisfied?(product_package, error_reporter),
          is_pricing_model_satisfied?(product_package, error_reporter)
        ].all?
      end

      def is_pricing_model_satisfied?(product_package, error_reporter)
        return true if product_package.pricing_model_id.blank?
        pricing_model = ::BenefitMarkets::PricingModels::PricingModel.where({:id => product_package.pricing_model_id}).first
        if pricing_model.nil?
          error_reporter.errors.add(:pricing_model_id, "does not exist")
          return false
        end
        true
      end

      def is_contribution_model_satisfied?(product_package, error_reporter)
        return true if product_package.contribution_model_id.blank?
        pricing_model = ::BenefitMarkets::ContributionModels::ContributionModel.where({:id => product_package.contribution_model_id}).first
        if pricing_model.nil?
          error_reporter.errors.add(:contribution_model, "does not exist")
          return false
        end
        true
      end
    end
  end
end
