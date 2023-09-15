# frozen_string_literal: true

module BenefitSponsors
  module BenefitSponsorships
    module ShopOsseEligibilities
      # Eligibility model
      class ShopOsseEligibility < ::Eligible::Eligibility

        embedded_in :benefit_sponsorship, class_name: '::BenefitSponsors::BenefitSponsorships::BenefitSponsorship'

        evidence :shop_osse_evidence, class_name: '::BenefitSponsors::BenefitSponsorships::ShopOsseEligibilities::AdminAttestedEvidence'

        grant :contribution_subsidy_grant, class_name: 'BenefitSponsors::BenefitSponsorships::ShopOsseEligibilities::ShopOsseGrant'

        grant :min_employee_participation_relaxed_grant,
              class_name: 'BenefitSponsors::BenefitSponsorships::ShopOsseEligibilities::ShopOsseGrant'

        grant :min_fte_count_relaxed_grant,
              class_name: 'BenefitSponsors::BenefitSponsorships::ShopOsseEligibilities::ShopOsseGrant'

        grant :min_contribution_relaxed_grant,
              class_name: 'BenefitSponsors::BenefitSponsorships::ShopOsseEligibilities::ShopOsseGrant'

        grant :metal_level_products_restricted_grant,
              class_name: 'BenefitSponsors::BenefitSponsorships::ShopOsseEligibilities::ShopOsseGrant'

      end
    end
  end
end
