# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitSponsors
  module Operations
    module BenefitSponsorships
      module ShopOsseEligibilities
        # Operation to support eligibility creation
        class CreateShopOsseEligibility
          send(:include, Dry::Monads[:result, :do])

          # @param [Hash] opts Options to build eligibility
          # @option opts [<GlobalId>] :subject required
          # @option opts [<String>]   :evidence_key required
          # @option opts [<String>]   :evidence_value required
          # @option opts [Date]       :effective_date required
          # @option opts [<Symbol>]   :event required
          # @return [Dry::Monad] result
          def call(params)
            values = yield validate(params)
            eligibility_options = yield build_eligibility_options(values)
            eligibility = yield create_eligibility(eligibility_options)
            eligibility_record = yield store(values, eligibility)

            Success(eligibility_record)
          end
  
          private
  
          def validate(params)
            params[:event] ||= :initialize
            params[:effective_date] ||= Date.today

            errors = []
            errors << 'subject missing' unless params[:subject]
            errors << 'evidence key missing' unless params[:evidence_key]
            errors << 'evidence value missing' unless params[:evidence_value]
            errors << 'effective date missing' unless params[:effective_date]
            errors << 'event missing' unless params[:event]
          
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

          def store(values, eligibility)
            osse_eligibility_params = eligibility.to_h.except(:evidences, :grants)
            eligibility_record = BenefitSponsors::BenefitSponsorships::ShopOsseEligibilities::ShopOsseEligibility.new(osse_eligibility_params)

            eligibility_record.tap do |record|
              record.evidences = record.class.create_objects(eligibility.evidences, :evidences)
              record.grants = record.class.create_objects(eligibility.grants, :grants)
            end

            subject = GlobalID::Locator.locate(values[:subject])
            subject.eligibilities << eligibility_record
            subject.save!

            if subject.save
              Success(eligibility_record)
            else
              Failure(subject.errors.full_messages)
            end
          end
        end
      end
    end
  end
end
