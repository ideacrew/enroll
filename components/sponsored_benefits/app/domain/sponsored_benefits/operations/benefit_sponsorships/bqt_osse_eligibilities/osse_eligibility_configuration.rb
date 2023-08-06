# frozen_string_literal: true

module SponsoredBenefits
  module Operations
    module BenefitSponsorships
      module BqtOsseEligibilities
        # Overrides top level eligibility_configuration for feature specific configurations
        class OsseEligibilityConfiguration < ::Operations::Eligible::EligibilityConfiguration
          def self.key
            :bqt_osse_eligibility
          end

          def self.title
            "BQT Osse Eligibility"
          end

          def self.grants
            %i[
              contribution_subsidy_grant
              min_employee_participation_relaxed_grant
              min_fte_count_relaxed_grant
              min_contribution_relaxed_grant
              metal_level_products_restricted_grant
            ]
          end
        end
      end
    end
  end
end
