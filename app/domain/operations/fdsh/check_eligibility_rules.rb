# frozen_string_literal: true

module Operations
  module Fdsh
    # This class defines a set of validation rules for different types of eligibility requests.
    # The process method calls each validation rule for the given request type and returns a Success result if all rules pass, or a Failure result if any rule fails.
    class CheckEligibilityRules
      include Dry::Monads[:result, :do, :try]

      # Define the validation rules for each request type
      RULES = {
        ssa: [:validate_ssn],
        dhs: [],
        local_residency: [],
        income_evidence: [:validate_ssn],
        esi_evidence: [:validate_ssn],
        non_esi_evidence: [:validate_ssn],
        local_mec_evidence: [:validate_ssn]
      }.freeze

      # Call the validation process for the given payload and request type
      def call(payload, request_type)
        rules_verified = yield process(payload, request_type)

        Success(rules_verified)
      end

      private

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

      def validate_ssn(payload)
        encrypted_ssn = payload.person_demographics.encrypted_ssn || payload.person_identifying_information.encrypted_ssn
        return Failure('No SSN for member') if encrypted_ssn.nil? || encrypted_ssn.empty?
        Operations::Fdsh::EncryptedSsnValidator.new.call(encrypted_ssn)
      end
    end
  end
end