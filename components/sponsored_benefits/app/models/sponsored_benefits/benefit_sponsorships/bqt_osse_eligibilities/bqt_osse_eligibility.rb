# frozen_string_literal: true

module SponsoredBenefits
  module BenefitSponsorships
    module BqtOsseEligibilities
      # Eligibility model
      class BqtOsseEligibility < ::Eligible::Eligibility

        embedded_in :benefit_sponsorship, class_name: '::SponsoredBenefits::BenefitSponsorships::BenefitSponsorship'

        evidence :bqt_osse_evidence, class_name: '::SponsoredBenefits::BenefitSponsorships::BqtOsseEligibilities::AdminAttestedEvidence'

        grant :contribution_subsidy_grant, class_name: 'SponsoredBenefits::BenefitSponsorships::BqtOsseEligibilities::BqtOsseGrant'

        grant :min_employee_participation_relaxed_grant,
              class_name: 'SponsoredBenefits::BenefitSponsorships::BqtOsseEligibilities::BqtOsseGrant'

        grant :min_fte_count_relaxed_grant,
              class_name: 'SponsoredBenefits::BenefitSponsorships::BqtOsseEligibilities::BqtOsseGrant'

        grant :min_contribution_relaxed_grant,
              class_name: 'SponsoredBenefits::BenefitSponsorships::BqtOsseEligibilities::BqtOsseGrant'

        grant :metal_level_products_restricted_grant,
              class_name: 'SponsoredBenefits::BenefitSponsorships::BqtOsseEligibilities::BqtOsseGrant'

      end
    end
  end
end
