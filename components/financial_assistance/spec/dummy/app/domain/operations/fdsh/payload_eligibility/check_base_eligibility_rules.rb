# frozen_string_literal: true

module Operations
  module Fdsh
    module PayloadEligibility
    # This class defines a set of validation rules for different types of eligibility requests.
    # The process method calls each validation rule for the given request type and returns a Success result if all rules pass, or a Failure result if any rule fails.
      class CheckBaseEligibilityRules
        # run tests after splitting - ensure existing tests pass
        include Dry::Monads[:do, :result]

        # # Define the validation rules for each request type
        RULES = {
          ssa: [:validate_ssn],
          dhs: [],
          local_residency: [],
          income: [:validate_ssn],
          esi_mec: [:validate_ssn],
          non_esi_mec: [:validate_ssn],
          local_mec: [:validate_ssn]
        }.freeze

        # Call the validation process for the given payload and request type
        def call(payload_entity, request_type)
          yield validate(payload_entity, request_type)
          rules_verified = yield process(payload_entity, request_type)

          Success(rules_verified)
        end

        private

        # validates against all request types, used both by person and application-type hub calls
        def validate(request_type)
          return Failure("Invalid Request Type #{request_type}") unless RULES.key?(request_type)
          Success()
        end

        # Process the validation rules for the given payload and request type
        def process(payload, request_type)
          rules = RULES[request_type]
          result = rules.map { |rule| send(rule, payload) }.flatten.compact

          # Return a Failure result if any of the validation rules fail
          if result.any?(Failure)
            errors = result.select { |r| r.is_a?(Failure) }.map(&:failure)
            Failure(errors)
          else
            Success()
          end
        end
      end
    end
  end
end