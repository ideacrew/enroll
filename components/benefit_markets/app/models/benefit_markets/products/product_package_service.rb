module BenefitMarkets
  module Products
    class ProductPackageService
      attr_reader :product_package_factory

      def initialize(factory_kind = ::BenefitMarkets::Products::ProductPackageFactory)
        @product_package_factory = factory_kind
      end

      # Load any needed metadata for the form, such as required attributes
      # and option lists. This service method isolates the form from having
      # a dependency on persistence models just so it can have dropdown lists.
      # @param form [Object] the form to load the data into
      # @return [Object] the form object populated with the metadata
      def load_form_metadata(form)
        form.allowed_benefit_option_kinds = benefit_option_kinds
        form.available_pricing_models = options_for_pricing_model_id(form)
        form.available_contribution_models = options_for_contribution_model_id
        form.available_benefit_catalogs = options_for_benefit_catalog_id
        form
      end

      # Load default attributes for the form from the persistance layer.
      # This service method isolates the persistence level attribute defaults
      # from how they should be presented on a form.
      # @param form [Object] the form to load the defaults into
      # @return [Object] the form object populated with the metadata
      def load_default_form_params(form)
        # Nothing for this model
        form
      end

      # Load the peristance entities and use them to populate the form
      # attributes.
      #
      # Normally this method would contain only a persistence lookup and
      # attribute mappings.
      # In my case I have to figure out which form subclass I should be using.
      # @param form [Object] The form for which to load the parameters.
      # @return [Object] A form object containing the loaded parameters.
      def load_form_params_from_resource(form)
        product_package = find_model_by_id(form.id)
        form = ProductPackageForm.resolve_form_subclass(product_package.benefit_option_kind).new
        attributes_to_form_params(product_package, form)
      end

      # Save the new form into it's corresponding persistance entities.
      # @param form [Object] the form to save
      # @return [Tuple<Boolean, Object>] the result of the save attempt as
      # well as any object that should be used for routing
      def save(form) 
        product_package = build_object_using_factory(form)
        store(form, product_package)
      end

      # Persist the changes to the form against an already existing entity.
      # @param form [Object] the form to save
      # @return [Tuple<Boolean, Object>] the result of the update attempt as
      # well as any object that should be used for routing
      def update(form) 
        product_package = find_model_by_id(form.id)
        form_params_to_attributes(form, product_package)
        store(form, product_package)
      end

      protected

      def attributes_to_form_params(product_package, form)
        form.attributes = {
          id: product_package.id,
          benefit_option_kind: product_package.benefit_option_kind,
          benefit_catalog_id: product_package.benefit_catalog_id,
          title: product_package.title,
          contribution_model_id: product_package.contribution_model_id,
          pricing_model_id: product_package.pricing_model_id
        }
        if form.respond_to?(:metal_level)
          form.metal_level = product_package.metal_level
        end
        if form.respond_to?(:issuer_id)
          form.issuer_id = product_package.issuer_id
        end
        form
      end

      def form_params_to_attributes(form, product_package)
        model_attributes = {
          benefit_catalog: benefit_catalog_for(form),
          title: form.title,
          contribution_model: contribution_model_for(form),
          pricing_model: pricing_model_for(form)
        }
        if form.respond_to?(:metal_level)
          model_attributes[:metal_level] = form.metal_level
        end
        if form.respond_to?(:issuer_id)
          model_attributes[:issuer_id] = form.issuer_id
        end
        product_package.assign_attributes(model_attributes)
      end

      def store(form, product_package)
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

      def find_model_by_id(id)
        ::BenefitMarkets::Products::ProductPackage.find(id)
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
          build_product_package(form, issuer_id: form.issuer_id)
        when "metal_level_health"
          build_product_package(form, metal_level: form.metal_level)
        else
          build_product_package(form)
        end
      end

      def build_product_package(form, **other_options)
        product_package_factory.call(
          benefit_option_kind: form.benefit_option_kind,
          benefit_catalog: benefit_catalog_for(form),
          title: form.title,
          contribution_model: contribution_model_for(form),
          pricing_model: pricing_model_for(form),
          **other_options
        )
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
    end
  end
end
