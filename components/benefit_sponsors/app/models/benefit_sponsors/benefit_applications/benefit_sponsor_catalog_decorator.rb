module BenefitSponsors
  module BenefitApplications
    class BenefitSponsorCatalogDecorator < SimpleDelegator

      Product = Struct.new(:id, :title, :metal_level_kind, :carrier_name, :sole_source, :coverage_kind)
      ContributionLevel = Struct.new(:id, :display_name, :contribution_factor, :is_offered)

      def sponsor_contributions
        product_packages.inject({}) do |contributions, product_package|
          contribution_service = BenefitSponsors::SponsoredBenefits::ProductPackageToSponsorContributionService.new
          contribution = contribution_service.build_sponsor_contribution(product_package)

          contributions[product_package.package_kind.to_s] = {
            id: nil,
            contribution_levels: contribution.contribution_levels.collect{|cl| 
                     ContributionLevel.new(cl.id, cl.display_name, cl.contribution_factor, cl.is_offered)
                    }
          }

          contributions
        end
      end


      def plan_option_kinds
        plan_options.keys
      end

      def carrier_names
        plan_options[:single_issuer].keys
      end

      def metal_levels
        plan_options[:metal_level].keys
      end

      def single_product_options
        plan_options[:single_product].keys
      end

      def probation_period_kinds
        [
          ["First of the month following or coinciding with date of hire", 'first_of_month'], 
          ["First of the month following 30 days", 'first_of_month_after_30_days'], 
          ["First of the month following 60 days", 'first_of_month_after_60_days']
        ]
      end

      def plan_options
        return @products if defined? @products
        @products = {}

        product_packages.each do |product_package|
          package_products = product_package.products.collect do |product|
            Product.new(product.id, product.title, product.metal_level_kind, carriers[product.issuer_profile_id.to_s], false, product.is_a?(BenefitMarkets::Products::HealthProducts::HealthProduct) ? "health" : "dental")
          end
          @products[product_package.package_kind] = case product_package.package_kind
            when :single_issuer
              package_products.group_by(&:carrier_name)
            when :metal_level
              package_products.group_by(&:metal_level_kind)
            else
              package_products.group_by(&:carrier_name)
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