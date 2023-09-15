# frozen_string_literal: true

module SponsoredBenefits
  module Operations
    module BenefitSponsorships
      module BqtOsseEligibilities
        # Overrides top level eligibility_configuration for feature specific configurations
        class OsseEligibilityConfiguration < ::Operations::Eligible::EligibilityConfiguration
          attr_reader :subject, :effective_date

          def initialize(params)
            @subject = params[:subject]
            @effective_date = params[:effective_date]

            super()
          end

          def key
            :bqt_osse_eligibility
          end

          def title
            "Aca BQT Osse Eligibility"
          end

          def benefit_market_catalog
            ::BenefitMarkets::BenefitMarketCatalog
              .by_application_date(effective_date)
              .detect { |bm| bm.kind == :aca_shop }
          end

          def eligibilities_source
            if subject.is_a?(BenefitMarkets::BenefitSponsorCatalog)
              subject.benefit_sponsorship
            else
              benefit_market_catalog
            end
          end

          def catalog_eligibility
            return unless eligibilities_source
            eligibilities_source
              .eligibilities
              .by_key("aca_shop_osse_eligibility_#{effective_date.year}")
              .first
          end

          def grants
            return [] unless catalog_eligibility

            catalog_eligibility.grants.collect do |grant|
              [grant.key, grant.value.item]
            end
          end
        end
      end
    end
  end
end
