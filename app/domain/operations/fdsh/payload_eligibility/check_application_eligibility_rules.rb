# frozen_string_literal: true

module Operations
  module Fdsh
    module PayloadEligibility
      # Inherits from CheckEligibilityRules
      class CheckApplicationEligibilityRules < CheckBaseEligibilityRules

        private

        def validate(payload_entity, request_type)
          return Failure("Invalid Application Object #{payload_entity}") unless payload_entity.is_a?(AcaEntities::MagiMedicaid::Application)
          super(request_type)
        end

        def validate_ssn(payload)
          result = payload.applicants.map do |applicant|
            encrypted_ssn = applicant.identifying_information.encrypted_ssn
            return Failure("No SSN for applicant") if encrypted_ssn.nil? || encrypted_ssn.empty?

            result = Operations::Fdsh::EncryptedSsnValidator.new.call(encrypted_ssn)
            return result unless result.success?
          end

          Success()
        end
      end
    end
  end
end