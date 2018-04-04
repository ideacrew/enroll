module BenefitMarkets
  module Products
    class ProductPackageFactory

      attr_reader :title, :product_kind, :benefit_option_kind, :contribution_model_kind, :price_model_kind

      def self.call(params)
        new(params).product_package
      end

      def initialize(benefit_catalog, title, product_kind, benefit_option_kind, contribution_model_kind, price_model_kind=nil, product_list=[])

        @benefit_catalog            = benefit_catalog
        @title                      = title
        @product_kind               = product_kind
        @benefit_option_kind        = benefit_option_kind
        @contribution_model_kind    = contribution_model_kind
        @price_model_kind           = price_model_kind
        @product_list               = product_list

        validate_params

        @product_package = product_package_for(@product_kind)

        @product_package.benefit_option_kind = benefit_option_kind

        # @product_package do |config|
        # end
          
      end

      def product_package
        @product_package
      end

      def product_package_for(new_product_kind)
        namespace = ("BenefitMarkets::Products::#{new_product_kind.to_s}Products::").camelcase
        klass     = ("#{benefit_option_kind.to_s}_#{new_product_kind.to_s}ProductPackage").camelcase

        (namespace + klass).constantize.new
      end

      def benefit_option_kind(new_benefit_option_kind)
        # :one_product
        # :one_issuer

      end

      def contribution_model_kind(new_contribution_model_kind)
      end

      def price_model_kind
        return unless @price_model_kind.present?

        if @price_model_kind == :composite_rate && @product_list.size != 1
          raise(BenefitMarkets::Errors::CompositeRatePriceModelIncompatibleError, "only one product allowed for price model: #{@price_model_kind}")
        end

      end

      def add_products
        @product_list.reduce([]) do |list, product|
          list << product if is_product_criteria_satisfied?(product)
        end
      end

      private

      def is_product_criteria_satisfied?(product)
        status = true
        status = false unless product.kind == @product_kind
        status
      end

      def is_product_application_period_satisfied?(product)
        # Compare BenefitCatalog
      end

      def validate_params
        raise BenefitMarkets::Errors::UndefinedProductError           unless BenefitMarkets::PRODUCT_KINDS.include?(@product_kind)
        raise BenefitMarkets::Errors::UndefinedBenefitOptionError     unless BenefitMarkets::BENEFIT_OPTION_KINDS.include?(@benefit_option_kind)
        raise BenefitMarkets::Errors::UndefinedContributionModelError unless BenefitMarkets::CONTRIBUTION_MODEL_KINDS.include?(@benefit_option_kind)
        raise BenefitMarkets::Errors::UndefinedPriceModelError        unless BenefitMarkets::PRICE_MODEL_KINDS.include?(@price_model_kind)
      end

    end
  end
end
