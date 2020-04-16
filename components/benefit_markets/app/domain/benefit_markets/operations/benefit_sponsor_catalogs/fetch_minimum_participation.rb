module BenefitMarkets
  module Operations
    module BenefitSponsorCatalogs

      class FetchMinimumParticipation

        include Dry::Monads[:result, :do]

        # @param [ Hash ] params Benefit Sponsor Catalog attributes
        # @param [ Array<BenefitMarkets::Entities::ProductPackage> ] product_packages ProductPackage
        # @return [ BenefitMarkets::Entities::BenefitSponsorCatalog ] benefit_sponsor_catalog Benefit Sponsor Catalog
        def call(product_package:,  calender_year:)
          minimum_participation  = yield fetch(product_package, calender_year)
    
          Success(minimum_participation)
        end

        private

        def fetch(product_package, calender_year)
          contribution_model = product_package.assigned_contribution_model || product_package.contribution_model
          minimum_participation = ::EnrollRegistry["#{product_package.benefit_kind}_fetch_enrollment_minimum_participation_#{calender_year}"].setting(contribution_model.key).item

          Success(minimum_participation)
        end
      end
    end
  end
end