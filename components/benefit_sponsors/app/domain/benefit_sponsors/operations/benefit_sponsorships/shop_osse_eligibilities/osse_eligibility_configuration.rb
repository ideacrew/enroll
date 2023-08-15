# frozen_string_literal: true

module BenefitSponsors
  module Operations
    module BenefitSponsorships
      module ShopOsseEligibilities
        # Overrides top level eligibility_configuration for feature specific configurations
        class OsseEligibilityConfiguration < ::Operations::Eligible::EligibilityConfiguration
          attr_reader :subject, :effective_date

          def initialize(params)
            @subject = params[:subject]
            @effective_date = params[:effective_date]

            super()
          end

          def key
            catalog_eligibility&.key || "aca_shop_osse_eligibility_#{effective_date.year}".to_sym
          end

          def title
            catalog_eligibility&.title || "Aca Shop Osse Eligibility"
          end

          def benefit_market_catalog
            ::BenefitMarkets::BenefitMarketCatalog
              .by_application_date(effective_date)
              .detect { |bm| bm.kind == :aca_shop }
          end

          def catalog_eligibility
            return unless benefit_market_catalog
            benefit_market_catalog
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
