# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitSponsors
  module Operations
    module BenefitSponsorships
      module ShopOsseEligibility
        # Operation to support eligibility creation
        class BuildShopOsseGrant
          send(:include, Dry::Monads[:result, :do])

          # @param [Hash] opts Options to build eligibility
          # @option opts [<Symbol>]   :grant_key required
          # @option opts [<String>]   :grant_value required
          # @return [Dry::Monad] result
          def call(params)
            values = yield validate(params)
            grant_options = yield build_grant_options(values)

            Success(grant_options)
          end

          private

          def validate(params)
            errors = []
            errors << 'grant key missing' unless params[:grant_key]
            errors << 'grant value missing' unless params[:grant_value]

            errors.empty? ? Success(params) : Failure(errors)
          end

          def build_grant_options(values)
            Success({
                      title: values[:grant_key].to_s.titleize,
                      key: values[:grant_key].to_sym,
                      value: {
                        title: values[:grant_key].to_s.titleize,
                        key: values[:grant_key].to_sym,
                        item: values[:grant_value]
                      }
                    })
          end
        end
      end
    end
  end
end
