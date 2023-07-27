# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitSponsors
  module Operations
    module BenefitSponsorships
      module ShopOsseEligibility
        # Operation to support eligibility creation
        class PersistEligibility
          send(:include, Dry::Monads[:result, :do])

          # @param [Hash] opts Options to build eligibility
          # @option opts [<String>]   :evidence_key required
          # @option opts [<String>]   :evidence_value required
          # @option opts [<Symbol>]   :event required
          # @option opts [Date]       :effective_date required
          # @return [Dry::Monad] result
          def call(params)
            values = yield validate(params)
            eligibility_options = yield build_eligibility_options(values)
            eligibility = yield create_eligibility(eligibility_options)
            # eligibility_record = persit(subject, eligibility)
            Success(eligibility)
          end
  
          private
  
          def validate(params)
            unless params[:event]
              params[:event] ||= :initialize
              params[:effective_date] ||= Date.today
            end

            errors = []
            errors << 'evidence key missing' unless params[:evidence_key]
            errors << 'evidence value missing' unless params[:evidence_value]
            errors << 'effective date missing' unless params[:effective_date]
            errors << 'effective date missing' unless params[:event]

            errors.empty? ? Success(params) : Failure(errors)
          end

          def build_eligibility_options(values)
            BuildShopOsseEligibility.new.call(values)
          end

          def create_eligibility(eligibility_options)
            AcaEntities::Eligible::AddEligibility.new.call(
              subject: 'AcaEntities::BenefitSponsors::BenefitSponsorships::BenefitSponsorship',
              eligibility: eligibility_options
            )
          end

          def persist(subject, eligibility)
            eligibility = subject.eligibilies.build(eligibility.to_h)
            eligibility.save
          end
        end
      end
    end
  end
end
