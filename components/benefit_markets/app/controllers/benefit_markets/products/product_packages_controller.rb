module BenefitMarkets
  module Products
    class ProductPackagesController < ::BenefitMarkets::ApplicationController
      include Pundit

      def new
        @product_package = ::BenefitMarkets::Products::ProductPackageForm.for_new(params.require(:benefit_option_kind))
        authorize @product_package
      end

      def create
        @product_package = ::BenefitMarkets::Products::ProductPackageForm.for_create(package_params)
        authorize @product_package
        if @product_package.save
          redirect_to products_product_package_url(@product_package.show_page_model)
        else
          render "new"
        end
      end

      def edit
        @product_package = ::BenefitMarkets::Products::ProductPackageForm.for_edit(params.require(:id))
        authorize @product_package
      end

      def update
        @product_package = ::BenefitMarkets::Products::ProductPackageForm.for_update(params.require(:id))
        authorize @product_package
        if @product_package.update_attributes(package_params)
          redirect_to products_product_package_url(@product_package.show_page_model)
        else
          render "edit"
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
