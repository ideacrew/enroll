# frozen_string_literal: true

module BenefitSponsors
  module BenefitSponsorships
    module ShopOsseEligibility
      # Eligibility model
      class Eligibility
        include Mongoid::Document
        include Mongoid::Timestamps
        include ::Eligible::Concerns::Eligibility

        embeds_one :shop_osse_evidence,
                   class_name:
                     '::BenefitSponsors::BenefitSponsorships::ShopOsseEligibility::AdminAttestedEvidence'

        embeds_one :contribution_subsidy_grant,
                   class_name:
                     '::BenefitSponsors::BenefitSponsorships::ShopOsseEligibility::Grant'
        embeds_one :min_employee_participation_relaxed_grant,
                   class_name:
                     '::BenefitSponsors::BenefitSponsorships::ShopOsseEligibility::Grant'
        embeds_one :min_fte_count_relaxed_grant,
                   class_name:
                     '::BenefitSponsors::BenefitSponsorships::ShopOsseEligibility::Grant'
        embeds_one :min_contribution_relaxed_grant,
                   class_name:
                     '::BenefitSponsors::BenefitSponsorships::ShopOsseEligibility::Grant'
        embeds_one :metal_level_products_restricted_grant,
                   class_name:
                     '::BenefitSponsors::BenefitSponsorships::ShopOsseEligibility::Grant'
      end
    end
  end
end
