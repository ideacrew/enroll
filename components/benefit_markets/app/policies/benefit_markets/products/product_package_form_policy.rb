module BenefitMarkets
  module Products
    class ProductPackageFormPolicy
      def initialize(current_user, product_package_form)
        @user = current_user
        @product_package_form = product_package_form
        # We will need this if the authorization logic starts to look actual package
        @form_mapper = ::BenefitMarkets::Products::ProductPackageFormMapping.new
      end

      def new?
        true
      end

      def create?
        true
      end
    end
  end
end
