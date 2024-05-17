module BenefitMarkets
  module Operations
    module BenefitSponsorCatalogs

      class FetchMinimumParticipation

        include Dry::Monads[:do, :result]

        # Fetches the minimum participation from a product package for a given calendar year.
        #
        # @param params [Hash] A hash containing :product_package and :calender_year keys.
        #   - :product_package [BenefitMarkets::Products::ProductPackage] The product package to fetch the minimum participation from.
        #   - :calender_year [Integer] The calendar year to fetch the minimum participation for.
        #
        # @return [Dry::Monads::Result] A Success monad with the minimum participation.
        def call(params)
          product_package,  calender_year = params.values_at(:product_package, :calender_year)

          minimum_participation  = yield fetch(product_package, calender_year)
    
          Success(minimum_participation)
        end

        private

        def fetch(product_package, calender_year)
          if contribution_key = product_package&.contribution_model&.key
            minimum_participation = ::EnrollRegistry["#{product_package.benefit_kind}_fetch_enrollment_minimum_participation_#{calender_year}"].setting(product_package.contribution_model.key)&.item
            if minimum_participation.present?
              Success(minimum_participation)
            else
              Failure("unable to find minimum contribution for given contribution model.")
            end
          else
            Failure("contribution key missing.")
          end
        end
      end
    end
  end
end