module BenefitSponsors
  module Importers::Mhc
    class ConversionEmployerDentalInitializer < ConversionEmployerPlanYearCreate
        include ::BenefitSponsors::Importers::ConversionEmployerEmployeeLookUp

      def map_products
        sponsored_benefit = BenefitSponsors::SponsoredBenefits::DentalSponsoredBenefit.new
        sponsored_benefit.product_package_kind = :single_product
        employer = find_employer(fein)
        benefit_package = find_benefit_package(employer)
        sponsored_benefit.benefit_package = benefit_package
        if sponsored_benefit.product_package.present?
          sponsored_benefit.reference_product = sponsored_benefit.product_package.products.where(hios_id: single_plan_hios_id).first
          raise StandardError, "Unable find reference product" if sponsored_benefit.reference_product.blank?
          sponsored_benefit.product_option_choice = sponsored_benefit.reference_product.issuer_profile.id
        end
        composite_tier_contributions = tier_contribution_values
        construct_sponsored_benefit(sponsored_benefit, composite_tier_contributions)
      end

      def construct_sponsored_benefit(sponsored_benefit, tier_contributions)
        sponsored_benefit.sponsor_contribution = BenefitSponsors::SponsoredBenefits::SponsorContribution.sponsor_contribution_for(sponsored_benefit.product_package)

        if sponsored_benefit.sponsor_contribution.blank?
          raise StandardError, "Sponsor Contribution construction failed!!"
        end

        sponsored_benefit.sponsor_contribution.contribution_levels.each do |new_contribution_level|
          contribution_match = tier_contributions.detect{|contribution| (((contribution[:relationship] == "child_under_26") ? "dependent" : contribution[:relationship]) == new_contribution_level.contribution_unit.name)}
          if contribution_match.present?
            new_contribution_level.is_offered = contribution_match[:offered]
            new_contribution_level.contribution_factor = (contribution_match[:premium_pct].to_f / 100)
          end
        end
      end

      def save
         map_products
      end
    end
  end
end