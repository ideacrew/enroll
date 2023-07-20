# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitSponsors
  module Operations
    module BenefitSponsorships
      module ShopOsseEligibility
        # Operation to support eligibility creation
        class BuildGrant
          send(:include, Dry::Monads[:result, :do])

          # @param [Hash] opts Options to build eligibility
          # @option opts [<Symbol>]   :grant_key required
          # @option opts [<Symbol>]   :grant_key required
          # @option opts [<String>]   :grant_value required
          # @option opts [<Boolean>]  :is_eligible required
          # @option opts [Date]       :effective_date required
          # @return [Dry::Monad] result
          def call(params)
            values = yield validate(params)
            grant_params = yield build_grant_params(values)
            entity = yield create(grant_params)
            evidence = yield build(entity, values)

            Success(evidence)
          end

          private

          def validate(params)
            errors = []
            errors << 'grant type missing' unless params[:grant_type]
            errors << 'grant key missing' unless params[:grant_key]
            errors << 'grant value missing' unless params[:grant_value]
            errors << 'is_eligible missing' unless params.key?(:is_eligible)
            errors << 'effective date missing' unless params[:effective_date]

            errors.empty? ? Success(params) : Failure(errors)
          end

          def build_grant_params(values)
            Success({
                      title: values[:grant_type].to_s.titleize,
                      key: values[:grant_type].to_sym,
                      value: {
                        title: values[:grant_key].to_s.titleize,
                        key: values[:grant_key].to_sym,
                        item: values[:grant_value]
                      },
                      state_histories: [
                                          {
                                            is_eligible: false,
                                            from_state: :draft,
                                            to_state: :draft,
                                            event: :initialize,
                                            transition_at: DateTime.now,
                                            effective_on: values[:effective_date],
                                            comment: "evidence inititalized"
                                          }
                                        ]
                    })
          end

          def create(grant_params)
            CreateGrant.new.call(grant_params)
          end

          def build(entity, values)
            grant = BenefitSponsors::BenefitSponsorships::ShopOsseEligibility::Grant.new(entity.to_h)

            if values[:is_eligible]
              grant.move_to_active(values.slice(:effective_date))
            else
              grant.move_to_expired(values.slice(:effective_date))
            end

            Success(grant)
          end
        end
      end
    end
  end
end
