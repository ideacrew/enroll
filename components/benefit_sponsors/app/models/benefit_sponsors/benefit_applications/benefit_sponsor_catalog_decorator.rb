module BenefitSponsors
  module BenefitApplications
    class BenefitSponsorCatalogDecorator < SimpleDelegator

      Product = Struct.new(:id, :title, :metal_level_kind, :carrier_name, :sole_source, :coverage_kind)

      def plan_option_kinds
        plan_options.keys
      end

      def plan_option_kind_filters
        plan_option_kinds.inject({}) do |filters, option_kind|
          filters[option_kind] = plan_options[option_kind].keys
          filters
        end
      end

      def carrier_names
        plan_option_kind_filters[:single_issuer]
      end

      def metal_levels
        plan_option_kind_filters[:metal_level]
      end

      def plan_options
        return @products if defined? @products
        @products = {}

        product_packages.each do |product_package|
          package_products = product_package.products.collect do |product|
            Product.new(product.id, product.title, product.metal_level_kind, carriers[product.issuer_profile_id.to_s], false, product.is_a?(BenefitMarkets::Products::HealthProducts::HealthProduct) ? "health" : "dental")
          end
          @products[product_package.kind] = case product_package.kind
            when :single_issuer
              package_products.group_by(&:carrier_name)
            when :metal_level
              package_products.group_by(&:metal_level_kind)
            else
              {:single_product => package_products}
            end
        end

        @products
      end

      def carriers
        return @carriers if defined? @carriers
        issuer_orgs = BenefitSponsors::Organizations::Organization.where(:"profiles._type" => "BenefitSponsors::Organizations::IssuerProfile")
        @carriers = issuer_orgs.inject({}) do |issuer_hash, issuer_org|
          issuer_profile  = issuer_org.profiles.where(:"_type" => "BenefitSponsors::Organizations::IssuerProfile").first
          issuer_hash[issuer_profile.id.to_s] = issuer_org.legal_name
          issuer_hash
        end
      end

      def carrier_level_options
        plan_options.group_by(&:carrier_name)
      end

      def metal_level_options
        plan_options.group_by(&:metal_level_kind)
      end

      def single_plan_options
        plan_options
      end
    end
  end
end