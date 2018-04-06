module BenefitMarkets
  module Products
    module ProductPackages
      class ProductPackageForm
        include ActiveModel::Model
        include ActiveModel::Validations

        attr_accessor :title
        attr_accessor :contribution_model_id
        attr_accessor :pricing_model_id
        attr_accessor :product_year # Actually belongs to product_catalog
        attr_accessor :benefit_catalog_id
        attr_accessor :benefit_option_kind
        attr_accessor :product_package_factory

        validates_presence_of :title, :allow_blank => false
        validates_presence_of :pricing_model_id, :allow_blank => false
        validates_presence_of :contribution_model_id, :allow_blank => false
        validates_presence_of :product_year, :allow_blank => false
        validates_inclusion_of :benefit_option_kind, :in => :allowed_benefit_option_kinds, :allow_blank => false

        def allowed_benefit_option_kinds
          product_package_factory.allowed_benefit_option_kinds
        end

        def self.form_for_new(benefit_option_kind)
          "::BenefitMarkets::Products::ProductPackages::#{benefit_option_kind.to_s.camelcase}ProductPackageForm".constantize.new(
            :benefit_option_kind => benefit_option_kind,
            :product_package_factory => ::BenefitMarkets::Products::ProductPackageFactory.new(benefit_option_kind)
          )
        end

        def self.form_for_create(opts)
          benefit_option_kind = opts.require(:benefit_option_kind)
          "::BenefitMarkets::Products::ProductPackages::#{benefit_option_kind.to_s.camelcase}ProductPackageForm".constantize.new(
            opts.merge({:product_package_factory => ::BenefitMarkets::Products::ProductPackageFactory.new(benefit_option_kind), benefit_option_kind: benefit_option_kind})
          )
        end

        def available_pricing_models
          product_package_factory.available_pricing_models.map do |pm|
            [pm.name, pm.id]
          end
        end

        def available_contribution_models
          product_package_factory.available_contribution_models.map do |pm|
            [pm.name, pm.id]
          end
        end

        def build_object_using_factory
          product_package_factory.build_product_package(
            benefit_catalog_id,
            title,
            contribution_model_id,
            pricing_model_id,
            product_year
          )
        end

        def has_additional_attributes?
          false
        end

        def save
          return false unless self.valid?
          factory_object = build_object_using_factory
          factory_object.save.tap do |valid|
            unless valid
              error_set = factory_object.errors
              error_set.each do |k, errs|
                self.errors.add(k, errs)
              end
            end
          end
        end
      end
    end
  end
end
