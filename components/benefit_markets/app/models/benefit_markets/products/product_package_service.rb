module BenefitMarkets
  module Products
    class ProductPackageService
      attr_reader :product_package_factory

      def initialize
        @factory_class = BenefitMarkets::Products::ProductPackageFactory
      end

      def build
        @factory_class.build
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
        form.available_benefit_option_kinds = options_for_benefit_option_kinds
        form.available_product_kinds = options_for_product_kinds
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
        product_package = find_model_from(form)
        attributes_to_form_params(product_package, form)
      end

      # Save the new form into it's corresponding persistance entities.
      # @param form [Object] the form to save
      # @return [Tuple<Boolean, Object>] the result of the save attempt as
      # well as any object that should be used for routing
      def save(form)
        product_package = build_product_package(form)
        store(form, product_package)
      end

      # Persist the changes to the form against an already existing entity.
      # @param form [Object] the form to save
      # @return [Tuple<Boolean, Object>] the result of the update attempt as
      # well as any object that should be used for routing
      def update(form)
        product_package = find_model_from(form)
        form_params_to_attributes(form, product_package)
        store(form, product_package)
      end

      def attributes_to_form_params(product_package, form)
        form.attributes = {
          id: product_package.persisted? ? product_package.id : nil,
          multiplicity: product_package.multiplicity,
          benefit_option_kind: product_package.kind,
          product_kind: product_package.product_kind,
          start_on: on_date_for(product_package, :first),
          end_on: on_date_for(product_package, :last),
          benefit_catalog_id: product_package.packagable.try(:id),
          title: product_package.title,
          contribution_model_id: product_package.contribution_model.try(:id),
          pricing_model_id: product_package.pricing_model.try(:id)
        }

        form
      end

      def form_params_to_attributes(form, product_package)
        model_attributes = {
          multiplicity: form.multiplicity,
          title: form.title,
          kind: form.benefit_option_kind,
          application_period: application_period_for(form),
          product_kind: product_package.product_kind,
          contribution_model: contribution_model_for(form),
          pricing_model: pricing_model_for(form)
        }
        product_package.assign_attributes(model_attributes)
      end

      def benefit_catalog_for(form)
        @benefit_catalog_for ||= ::BenefitMarkets::BenefitMarketCatalog.where(id: form.benefit_catalog_id).first
      end

      protected

      def store(form, product_package)
        valid_according_to_factory = @factory_class.validate(product_package)
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

      def find_model_from(form)
        benefit_catalog_for(form).product_packages.find(form.id)
      end

      def options_for_pricing_model_id(form)
        multiplicity = form.multiplicity ? :multiple : :single
        BenefitMarkets::PricingModels::PricingModel.where(:product_multiplicities.in => [ multiplicity ]).pluck(:name, :id)
        BenefitMarkets::PricingModels::PricingModel.all.pluck(:name, :id)
      end

      def options_for_contribution_model_id
        ::BenefitMarkets::ContributionModels::ContributionModel.where({}).map do |cm|
          [cm.title, cm.id]
        end
      end

      def options_for_benefit_catalog_id
        ::BenefitMarkets::BenefitMarketCatalog.where({}).map do |bc|
          [bc.title, bc.id]
        end
      end

      def options_for_benefit_option_kinds
        ['ACA Shop', 'ACA Individual', 'Medicaid', 'Medicare'].zip benefit_option_kinds
      end

      def options_for_product_kinds
        BenefitMarkets::PRODUCT_KINDS.map(&:to_s).map(&:humanize).map(&:titleize).zip BenefitMarkets::PRODUCT_KINDS
      end

      def benefit_option_kinds
        BenefitMarkets::BENEFIT_MARKET_KINDS.map(&:to_s)
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

      def build_product_package(form)
        @factory_class.call(
          form.attributes.extract!(:benefit_option_kind, :multiplicity, :product_kind, :title).merge(
            application_period: application_period_for(form),
            benefit_catalog: benefit_catalog_for(form),
            contribution_model: contribution_model_for(form),
            pricing_model: pricing_model_for(form),
            benefit_option_kind: form.benefit_option_kind
          )
        )
      end

      def application_period_for(form)
        Date.parse(form.start_on)..Date.parse(form.end_on) rescue nil
      end

      def contribution_model_for(form)
        @contribution_model_for ||= ::BenefitMarkets::ContributionModels::ContributionModel.where(id: form.contribution_model_id).first
      end

      def pricing_model_for(form)
        @pricing_model_for ||= ::BenefitMarkets::PricingModels::PricingModel.where(id: form.pricing_model_id).first
      end

      def on_date_for(product_package, direction)
        product_package.application_period.try(direction).try(:strftime, '%F')
      end
    end
  end
end
