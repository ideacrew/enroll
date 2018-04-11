module BenefitMarkets
  module Products
    class ProductPackageFactory
      def self.call(benefit_option_kind:, benefit_catalog:, title:, contribution_model:, pricing_model:, **other_params)
        build_product_package(benefit_option_kind, benefit_catalog, title, contribution_model, pricing_model, other_params)
      end

      def self.validate(product_package)
        [
          is_contribution_model_satisfied?(product_package),
          is_pricing_model_satisfied?(product_package)
        ].all?
      end

      protected

      def self.build_product_package(benefit_option_kind, benefit_catalog, title, contribution_model, pricing_model, other_params = {})
        select_model_subclass(benefit_option_kind).new(
          build_shared_params(benefit_catalog, title, contribution_model, pricing_model).merge(other_params)
        )
      end

      def self.select_model_subclass(benefit_option_kind)
        ::BenefitMarkets::Products::ProductPackage.subclass_for(benefit_option_kind)
      end

      def self.build_shared_params(benefit_catalog, title, contribution_model, pricing_model)
        {
          benefit_catalog: benefit_catalog,
          title: title,
          contribution_model: contribution_model,
          pricing_model: pricing_model
        }
      end

      def self.is_pricing_model_satisfied?(product_package)
        pricing_model = product_package.pricing_model
        return true if pricing_model.nil?
        unless pricing_model.product_multiplicities.include?(product_package.product_multiplicity)
          product_package.errors.add(:pricing_model_id, "does not match the multiplicity of the product package")
          return false
        end
        true
      end

      def self.is_contribution_model_satisfied?(product_package)
        contribution_model = product_package.contribution_model
        return true if product_package.contribution_model.nil?
        unless contribution_model.product_multiplicities.include?(product_package.product_multiplicity)
          product_package.errors.add(:contribution_model_id, "does not match the multiplicity of the product package")
          return false
        end
        true
      end
    end
  end
end
