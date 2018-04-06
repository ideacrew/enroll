module BenefitMarkets
  module Products
    class ProductPackagesController < ::BenefitMarkets::ApplicationController
      def new
        @product_package = ::BenefitMarkets::Products::ProductPackageForm.form_for_new(params.require(:benefit_option_kind))
      end

      def create
        @product_package = ::BenefitMarkets::Products::ProductPackageForm.form_for_create(package_params)
        if @product_package.save
          redirect_to products_product_packages_url
        else
          render "new"
        end
      end

      def index
        @product_packages = []
      end

      private

      def package_params
        params.require(:product_package).permit(
          :benefit_option_kind,
          :title,
          :pricing_model_id,
          :contribution_model_id,
          :product_year,
          :benefit_catalog_id,
          :issuer_id,
          :metal_level
        )
      end
    end
  end
end
