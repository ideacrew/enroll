module BenefitSponsors
  module Importers::Mhc
    class ConversionEmployerPlanYearUpdate < ConversionEmployerPlanYear
      include ::BenefitSponsors::Importers::ConversionEmployerEmployeeLookUp

      # def map_products
      #   sponsored_benefit = BenefitSponsors::SponsoredBenefits::DentalSponsoredBenefit.new
      #   sponsored_benefit.product_package_kind = :single_product
      #   employer = find_employer(fein)
      #   benefit_package = find_benefit_package(employer)
      #   sponsored_benefit.benefit_package = benefit_package
      #   if sponsored_benefit.product_package.present?
      #     sponsored_benefit.reference_product = sponsored_benefit.product_package.products.where(hios_id: single_plan_hios_id).first
      #     raise StandardError, "Unable find reference product" if sponsored_benefit.reference_product.blank?
      #     sponsored_benefit.product_option_choice = sponsored_benefit.reference_product.issuer_profile.id
      #   end
      #   composite_tier_contributions = tier_contribution_values
      #   construct_sponsored_benefit(sponsored_benefit, composite_tier_contributions)
      # end
      #
      # def construct_sponsored_benefit(sponsored_benefit, tier_contributions)
      #   sponsored_benefit.sponsor_contribution = BenefitSponsors::SponsoredBenefits::SponsorContribution.sponsor_contribution_for(sponsored_benefit.product_package)
      #
      #   if sponsored_benefit.sponsor_contribution.blank?
      #     raise StandardError, "Sponsor Contribution construction failed!!"
      #   end
      #
      #   sponsored_benefit.sponsor_contribution.contribution_levels.each do |new_contribution_level|
      #     contribution_match = tier_contributions.detect{|contribution| (((contribution[:relationship] == "child_under_26") ? "dependent" : contribution[:relationship]) == new_contribution_level.contribution_unit.name)}
      #     if contribution_match.present?
      #       new_contribution_level.is_offered = contribution_match[:offered]
      #       new_contribution_level.contribution_factor = (contribution_match[:premium_pct].to_f / 100)
      #     end
      #   end
      # end
      #
      #

      def save
        return unless self.valid?
        sponsored_benefit = build_sponsored_benefit
      end

      def build_sponsored_benefit
        benefit_package = find_benefit_package
        BenefitSponsors::SponsoredBenefits::SponsoredBenefitFactory.call(benefit_package, sanitized_sponsored_benefit_params)
      end

      def sanitized_sponsored_benefit_params
        {
            :kind => "dental",
            :product_option_choice => find_carrier.id,
            :product_package_kind => "single_product",
            :reference_plan_id => "",
            :sponsor_contribution_attributes =>
                {:contribution_levels_attributes => formed_params_for_contribution_levels}
        }
      end

      def formed_params_for_contribution_levels
        contribution_levels = Array.new
        dental_tiers = formed_dental_tier_contribution_levels
        dental_tiers.each do |contribution_level|
          relation = contribution_level[:relationship]
          contribution_name = relation_ship_mapping[relation]
          contribution_factor = contribution_level[:premium_pct]
          contribution_levels.push({:display_name => contribution_name, :contribution_factor => contribution_factor, :is_offered => true})
        end
      end

      def formed_dental_tier_contribution_levels
        contribution_level_names = [
            "employee_only",
            "employee_and_spouse",
            "employer_domestic_partner",
            "employer_child_under_26"
        ]
        contribution_level_names.inject([]) do |contributions, sponsor_level_name|
          contributions << {
              relationship: sponsor_level_name,
              premium_pct: eval("#{sponsor_level_name}_rt_contribution"),
          }
        end
      end

      def relation_ship_mapping
        {
            "employee_only" => "Employee",
            "employee_and_spouse" => "Spouse",
            "employer_domestic_partner" => "Domestic Partner",
            "employer_child_under_26" => "Child Under 26"
        }
      end
    end
  end
end
