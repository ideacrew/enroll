# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitSponsors
  module Operations
    module BenefitSponsorships
      module ShopOsseEligibility
        # Operation to support grant creation
        class CreateGrant
          send(:include, Dry::Monads[:result, :do])

          # @param [ Hash ] params Product Attributes
          # @return [ BenefitMarkets::Entities::Product ] product Product
          def call(params)
            values = yield validate(params)
            product = yield create(values)

            Success(product)
          end

          private

          def validate(params)
            result =
              AcaEntities::BenefitSponsors::BenefitSponsorships::ShopOsseEligibility::GrantContract.new.call(
                params
              )

            if result.success?
              Success(result.to_h)
            else
              result
            end
          end

          def create(values)
            benefit_sponsorship_entity = AcaEntities::BenefitSponsors::BenefitSponsorships::ShopOsseEligibility::Grant.new(values)

            Success(benefit_sponsorship_entity)
          end
        end
      end
    end
  end
end
