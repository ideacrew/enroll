# frozen_string_literal: true

module FinancialAssistance
  module Operations
    module Applications
      module Verifications
        # This class defines a set of validation rules for different types of eligibility requests.
        # The process method calls each validation rule for the given request type and returns a Success result if all rules pass, or a Failure result if any rule fails.
        class CheckEligibilityRules
          # run tests after splitting - ensure existing tests pass
          include Dry::Monads[:result, :do, :try]

          # # Define the validation rules for each request type
          # RULES = {
          #   income: [:validate_ssn],
          #   esi: [:validate_ssn],
          #   non_esi: [:validate_ssn],
          #   local_mec: [:validate_ssn]
          # }.freeze
          RULES = [
            :validate_ssn
          ].freeze

          # Call the validation process for the given payload and request type
          def call(payload_entity)
            yield validate(payload_entity)
            rules_verified = yield process(payload_entity)

            Success(rules_verified)
          end

          private

          def validate(payload_entity_applicant)
            return Failure('Invalid Applicant Object') unless payload_entity_applicant.is_a?(AcaEntities::MagiMedicaid::Applicant)
            Success()
          end

          # Process the validation rules for the given payload
          def process(payload)
            result = RULES.map { |rule| send(rule, payload) }.flatten.compact

            # Return a Failure result if any of the validation rules fail
            if result.any?(Failure)
              errors = result.select { |r| r.is_a?(Failure) }.map(&:failure)
              Failure(errors)
            else
              Success()
            end
          end

          def validate_ssn(applicant)
            encrypted_ssn = applicant.identifying_information.encrypted_ssn
            return Failure("No SSN for applicant") if encrypted_ssn.nil? || encrypted_ssn.empty?
            ::FinancialAssistance::Operations::Applications::Verifications::EncryptedSsnValidator.new.call(encrypted_ssn)
          end
        end
      end
    end
  end
end