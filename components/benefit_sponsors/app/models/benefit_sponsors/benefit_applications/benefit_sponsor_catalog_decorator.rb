module BenefitSponsors
  module BenefitApplications
    class BenefitSponsorCatalogDecorator < SimpleDelegator

      Product = Struct.new(:id, :name, :metal_level, :carrier_name, :sole_source, :coverage_kind)

      def carrier_names
        plan_options.map(&:carrier_name).uniq
      end

      def metal_levels
        plan_options.map(&:metal_level).uniq
      end

      def plan_options
        return @products if defined? @products
        @products = []
        product_packages.each do |product_package|
          @products += product_package.all_products.collect do |product|
            Product.new(product.id, product.name, product.metal_level, carriers[product.carrier_profile_id.to_s], product.coverage_kind)
          end
        end
        @products
      end

      def carriers
        return @carriers if defined? @carriers
        CarrierProfile.all.inject({}) {|carriers, carrier| carriers[carrier.id.to_s] = carrier.legal_name; carriers}
      end
    end
  end
end