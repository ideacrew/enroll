# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Eligibilities
    module Osse
      # Build eligibility for the subject with given eligibility and effective date
      class BuildEligibility
        send(:include, Dry::Monads[:result, :do])

        # @param [Hash] opts Options to build eligibility
        # @option opts [<GlobalID>] :subject_gid required
        # @option opts [<String>]   :evidence_key required
        # @option opts [<String>]   :evidence_value required
        # @option opts [Date]       :effective_date required
        # @return [Dry::Monad] result
        def call(params)
          values = yield validate(params)
          eligibility_params = yield build_eligibility(values)
          eligibility = yield create_eligibility(eligibility_params)

          Success(eligibility)
        end

        private

        def validate(params)
          errors = []
          errors << 'subject global id missing' unless params[:subject_gid]
          errors << 'evidence key missing' unless params[:evidence_key]
          errors << 'evidence value missing' unless params[:evidence_value]
          errors << 'effective date missing' unless params[:effective_date]

          if params[:effective_date] && EnrollRegistry.feature_enabled?("aca_ivl_osse_effective_beginning_of_year")
            subject = GlobalID::Locator.locate(params[:subject_gid])
            params[:effective_date] = params[:effective_date].beginning_of_year if ['ConsumerRole', 'ResidentRole'].include?(subject.class.to_s)
          end

          errors.empty? ? Success(params) : Failure(errors)
        end

        def build_eligibility(values)
          Success(
            {
              title: "#{values[:evidence_key]} Eligibility",
              start_on: values[:effective_date],
              subject: construct_subject(values).success,
              evidences: construct_evidences(values).success
            }
          )
        end

        def create_eligibility(eligibility_params)
          ::Operations::Eligibilities::Create.new.call(eligibility_params)
        end

        def construct_subject(values)
          subject_instance = GlobalID::Locator.locate(values[:subject_gid])

          Success(
            {
              title: "Subject for #{title(values[:evidence_key])}",
              key: values[:subject_gid].uri,
              klass: subject_instance.class.to_s
            }
          )
        end

        def construct_evidences(values)
          Success([
            {
              title: "Evidence for #{title(values[:evidence_key])}",
              key: values[:evidence_key],
              is_satisfied: is_satisfied?(values[:evidence_value])
            }
          ])
        end

        def is_satisfied?(value)
          return value if value.is_a?(Boolean)
          value.to_s == 'true'
        end

        def title(key)
          key.to_s.titleize
        end
      end
    end
  end
end
