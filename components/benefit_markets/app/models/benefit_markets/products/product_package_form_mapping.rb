module BenefitMarkets
  module Products
    class ProductPackageFormMapping
      attr_reader :product_package_factory

      def initialize(factory_kind = ::BenefitMarkets::Products::ProductPackageFactory)
        @product_package_factory = factory_kind
      end

      def options_for_pricing_model_id(form)
        product_multiplicity = package_product_multiplicity_for(form)
        ::BenefitMarkets::PricingModels::PricingModel.where({:product_multiplicities => product_multiplicity}).map do |pm|
          [pm.name, pm.id]
        end
      end

      def options_for_contribution_model_id
        ::BenefitMarkets::ContributionModels::ContributionModel.where({}).map do |cm|
          [cm.name, cm.id]
        end
      end

      def options_for_benefit_catalog_id
        ::BenefitMarkets::BenefitMarketCatalog.where({}).map do |bc|
          [bc.title, bc.id]
        end
      end

      def benefit_option_kinds
        ::BenefitMarkets::Products::ProductPackage::BENEFIT_OPTION_KINDS.map(&:to_s)
      end

      def save(form) 
        product_package = build_object_using_factory(form)
        valid_according_to_factory = product_package_factory.validate(product_package)
        unless valid_according_to_factory
          map_errors_for(product_package, onto: form)
          return [false, nil]
        end
        save_successful = product_package.save
        unless save_successful 
          map_errors_for(product_package, onto: form)
          return [false, nil]
        end
        [true, product_package]
      end

      protected

      def package_product_multiplicity_for(form)
        ::BenefitMarkets::Products::ProductPackage.subclass_for(form.benefit_option_kind).new.product_multiplicity
      end

      # We can cheat here because our form and our model are so
      # close together - normally this will be more complex
      def map_model_error_attribute(model_attribute_name)
        model_attribute_name
      end

      def map_errors_for(product_package, onto:)
        product_package.errors.each do |att, err|
          onto.errors.add(map_model_error_attribute(att), err)
        end
      end

      def build_object_using_factory(form)
        case form.benefit_option_kind.to_s
        when "issuer_health"
          build_issuer_product_package(form)
        when "metal_level_health"
          build_metal_level_product_package(form)
        else
          build_vanilla_product_package(form)
        end
      end

      def contribution_model_for(form)
        ::BenefitMarkets::ContributionModels::ContributionModel.where(id: form.contribution_model_id).first
      end

      def pricing_model_for(form)
        ::BenefitMarkets::PricingModels::PricingModel.where(id: form.pricing_model_id).first
      end

      def benefit_catalog_for(form)
        ::BenefitMarkets::BenefitMarketCatalog.where(id: form.benefit_catalog_id).first
      end

      def build_metal_level_product_package(form)
        product_package_factory.build_metal_level_product_package(
          form.benefit_option_kind,
          benefit_catalog_for(form),
          form.title,
          contribution_model_for(form),
          pricing_model_for(form),
          form.metal_level
        )
      end

      def build_issuer_product_package(form)
        product_package_factory.build_issuer_product_package(
          form.benefit_option_kind,
          benefit_catalog_for(form),
          form.title,
          contribution_model_for(form),
          pricing_model_for(form),
          form.issuer_id
        )
      end

      def build_vanilla_product_package(form)
        product_package_factory.build_product_package(
          form.benefit_option_kind,
          benefit_catalog_for(form),
          form.title,
          contribution_model_for(form),
          pricing_model_for(form)
        )
      end
    end
  end
end
