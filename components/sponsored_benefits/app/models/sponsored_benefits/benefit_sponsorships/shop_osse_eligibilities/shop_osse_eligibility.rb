# frozen_string_literal: true

module SponsoredBenefits
  module BenefitSponsorships
    module ShopOsseEligibilities
      # Eligibility model
      class ShopOsseEligibility < ::Eligible::Eligibility

        embedded_in :benefit_sponsorship, class_name: '::SponsoredBenefits::BenefitSponsorships::BenefitSponsorship'

        evidence :shop_osse_evidence, class_name: '::SponsoredBenefits::BenefitSponsorships::ShopOsseEligibilities::AdminAttestedEvidence'

        grant :contribution_subsidy_grant, class_name: 'SponsoredBenefits::BenefitSponsorships::ShopOsseEligibilities::ShopOsseGrant'

        grant :min_employee_participation_relaxed_grant,
              class_name: 'SponsoredBenefits::BenefitSponsorships::ShopOsseEligibilities::ShopOsseGrant'

        grant :min_fte_count_relaxed_grant,
              class_name: 'SponsoredBenefits::BenefitSponsorships::ShopOsseEligibilities::ShopOsseGrant'

        grant :min_contribution_relaxed_grant,
              class_name: 'SponsoredBenefits::BenefitSponsorships::ShopOsseEligibilities::ShopOsseGrant'

        grant :metal_level_products_restricted_grant,
              class_name: 'SponsoredBenefits::BenefitSponsorships::ShopOsseEligibilities::ShopOsseGrant'

      end
    end
  end
end
