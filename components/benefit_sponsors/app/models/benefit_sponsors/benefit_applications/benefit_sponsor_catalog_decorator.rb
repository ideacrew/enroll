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
            Product.new(product.id, product.name, product.metal_level, carriers[product.carrier_profile_id.to_s], false, product.coverage_kind)
          end
        end
        @products
      end

      def carriers
        return @carriers if defined? @carriers
        CarrierProfile.all.inject({}) {|carriers, carrier| carriers[carrier.id.to_s] = carrier.legal_name; carriers}
      end

      # TODO: calculate option kinds dynamically from products
      def plan_option_kinds
        ['Single Carrier', 'Metal Level', 'Single Plan']
      end

      def carrier_level_options
        plan_options.group_by(&:carrier_name)
      end

      def metal_level_options
        plan_options.group_by(&:metal_level)
      end

      def single_plan_options
        plan_options
      end
    end
  end
end