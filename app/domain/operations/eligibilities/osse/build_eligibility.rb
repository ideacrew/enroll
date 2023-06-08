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
        def call(values)
          attributes  = yield construct(values)
          eligibility = yield build_entity(attributes)

          Success(eligibility)
        end

        private

        def construct(values)
          Success(
            {
              title: "#{values[:evidence_key]} Eligibility",
              start_on: values[:effective_date],
              subject: construct_subject(values).success,
              evidences: construct_evidences(values).success
            }
          )
        end

        def build_entity(attributes)
          ::Operations::Eligibilities::Create.new.call(attributes)
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
