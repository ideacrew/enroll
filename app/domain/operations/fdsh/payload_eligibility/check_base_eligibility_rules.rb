# frozen_string_literal: true

module Operations
  module Fdsh
    module PayloadEligibility
    # This class defines a set of validation rules for different types of eligibility requests.
    # The process method calls each validation rule for the given request type and returns a Success result if all rules pass, or a Failure result if any rule fails.
      class CheckBaseEligibilityRules
        # run tests after splitting - ensure existing tests pass
        include Dry::Monads[:result, :do, :try]

        # # Define the validation rules for each request type
        RULES = {
          ssa: [:validate_ssn],
          dhs: [:validate_vlp_documents],
          local_residency: [],
          alive_status: [:validate_ssn, :is_member_enrolled?],
          income: [:validate_ssn],
          esi_mec: [:validate_ssn],
          non_esi_mec: [:validate_ssn],
          local_mec: [:validate_ssn]
        }.freeze

        # Call the validation process for the given payload and request type
        def call(entity_obj, request_type)
          yield validate(entity_obj, request_type)
          rules_verified = yield process(entity_obj, request_type)

          Success(rules_verified)
        end

        private

        # validates against all request types, used both by person and application-type hub calls
        def validate(request_type)
          return Failure("Invalid Request Type #{request_type}") unless RULES.key?(request_type)
          Success()
        end

        # Processes the validation rules for a given entity object and request type.
        #
        # @param entity_obj [Object] The entity object is a person_entity or applicant_entity.
        # @param request_type [Symbol] The request type is one of the keys from RULES.
        # @return [Dry::Monads::Result] A monadic result indicating success or failure.
        def process(entity_obj, request_type)
          rules = RULES[request_type]
          result = rules.map { |rule| send(rule, entity_obj) }.flatten.compact

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