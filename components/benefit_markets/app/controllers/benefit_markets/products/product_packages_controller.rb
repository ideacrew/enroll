module BenefitMarkets
  module Products
    class ProductPackagesController < ::BenefitMarkets::ApplicationController
      include Pundit

      def new
        @product_package = ::BenefitMarkets::Products::ProductPackageForm.for_new(current_user, params.require(:benefit_option_kind))
        authorize @product_package
      end

      def create
        @product_package = ::BenefitMarkets::Products::ProductPackageForm.for_create(current_user, package_params)
        authorize @product_package
        if @product_package.save
          redirect_to products_product_package_url(@product_package.show_page_model)
        else
          render "new"
        end
      end

      def show
        @product_package = ::BenefitMarkets::Products::ProductPackage.find(params.require(:id))
        authorize @product_package
      end

      private

      def package_params
        params.require(:product_package).permit(
          :benefit_option_kind,
          :title,
          :pricing_model_id,
          :contribution_model_id,
          :benefit_catalog_id,
          :issuer_id,
          :metal_level
        )
      end
    end
  end
end
