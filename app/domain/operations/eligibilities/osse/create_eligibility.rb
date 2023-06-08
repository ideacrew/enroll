# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Eligibilities
    module Osse
      # Create eligibility for the subject with given eligibility and effective date
      class CreateEligibility
        send(:include, Dry::Monads[:result, :do])
        include EventSource::Command
        include EventSource::Logging

        # @param [Hash] opts Options to build eligibility
        # @option opts [<GlobalID>] :subject_gid required
        # @option opts [<String>]   :evidence_key required
        # @option opts [<String>]   :evidence_value required
        # @option opts [Date]       :effective_date required
        # @return [Dry::Monad] result
        def call(params)
          values  = yield validate(params)
          entity  = yield build(values)
          subject = yield load_subject(values)
          output  = yield create(subject, entity)

          Success(output)
        end

        private

        def validate(params)
          errors = []
          errors << 'subject global id missing' unless params[:subject_gid]
          errors << 'evidence key missing' unless params[:evidence_key]
          errors << 'evidence value missing' unless params[:evidence_value]
          errors << 'effective date missing' unless params[:effective_date]

          if params[:effective_date]
            subject = GlobalID::Locator.locate(params[:subject_gid])

            params[:effective_date] = params[:effective_date].beginning_of_year if ['ConsumerRole', 'ResidentRole'].include?(subject.class.to_s)
          end

          errors.empty? ? Success(params) : Failure(errors)
        end

        def build(values)
          ::Operations::Eligibilities::Osse::BuildEligibility.new.call(values)
        end

        def load_subject(values)
          Success(GlobalID::Locator.locate(values[:subject_gid]))
        end

        def create(subject, entity)
          eligibility = subject.eligibilities.build(entity.to_h)

          if eligibility.save
            Success(eligibility)
          else
            Failure(eligibility.errors)
          end
        end

        def build_event(payload)
          event('events.crm_gateway.families.family_update', attributes: payload.to_h)
        end

        def publish(event)
          event.publish
          Success("Successfully published payload to CRM Gateway.")
        end
      end
    end
  end
end
