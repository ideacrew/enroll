# frozen_string_literal: true

require "dry/monads"
require "dry/monads/do"

# We need to group eligibilities by Subject Key
# Needs to create eligibility per calender year

module BenefitSponsors
  module Operations
    module BenefitSponsorships
      module ShopOsseEligibilities
        # Operation to support eligibility creation
        class MigrateBenefitSponsorEligibility
          send(:include, Dry::Monads[:result, :do])

          # @param [Hash] opts Options to build eligibility
          # @option opts [<String>]   :eligibility_key required
          # @option opts [<Array>]   :current_eligibilities required
          # @return [Dry::Monad] result
          def call(params)
            values = yield validate(params)
            subject = yield find_subject(values)
            result = yield migrate(subject, values)

            Success(result)
          end

          private

          def validate(params)
            errors = []
            errors << "eligibility key missing" unless params[:eligibility_key]
            unless params[:current_eligibilities].present?
              errors << "current eligibilities missing"
            end

            errors.empty? ? Success(params) : Failure(errors)
          end

          def find_subject(values)
            subject =
              GlobalID::Locator.locate(
                values[:current_eligibilities].first.subject.key
              )

            Success(subject)
          end

          def migrate(subject, values)
            values[:current_eligibilities].each do |eligibility|
              next unless eligibility.evidences.present?

              migrate_eligibility(subject, values, eligibility)
            end

            Success(true)
          end

          def migrate_eligibility(subject, values, eligibility)
            logger("initialize_eligibility_is_satisfied_as_false") do
              initialize_eligibility(subject, values, eligibility)
            end

            eligibility.evidences.each do |evidence|
              effective_date = eligibility.start_on
              effective_date = evidence.updated_at unless evidence.is_satisfied

              logger(
                "update_eligibility_is_satisfied_as_#{evidence.is_satisfied}"
              ) do
                eligibility_operation_for(values[:eligibility_key]).new.call(
                  {
                    subject: subject.to_global_id,
                    evidence_key: evidence_key_for(values[:eligibility_key]),
                    evidence_value: evidence.is_satisfied.to_s,
                    effective_date: effective_date
                  }
                )
              end
            end
          end

          def initialize_eligibility(subject, values, eligibility)
            eligibility_operation_for(values[:eligibility_key]).new.call(
              {
                subject: subject.to_global_id,
                evidence_key: evidence_key_for(values[:eligibility_key]),
                evidence_value: "false",
                effective_date: eligibility.start_on
              }
            )
          end

          def eligibility_operation_for(eligibility_key)
            if eligibility_key == :shop_osse_eligibility
              BenefitSponsors::Operations::BenefitSponsorships::ShopOsseEligibilities::CreateShopOsseEligibility
            else
              Operations::IvlOsseEligibilities::CreateIvlOsseEligibility
            end
          end

          def evidence_key_for(eligibility_key)
            if eligibility_key == :shop_osse_eligibility
              :shop_osse_evidence
            else
              :ivl_osse_evidence
            end
          end

          def logger(action)
            Rails.logger.info "started processing #{action}"
            result = yield

            if result.success?
              Rails.logger.info "completed processing #{action}"
              result.success
            else
              Rails.logger.error "failed processing #{action}"
              Rails.logger.error result.failure
              result.failure
            end
          end
        end
      end
    end
  end
end
