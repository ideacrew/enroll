# frozen_string_literal: true

module Operations
  module Fdsh
    module PayloadEligibility
      # Inherits from CheckEligibilityRules
      class CheckApplicantEligibilityRules < CheckBaseEligibilityRules

        private

        def validate(payload_entity_applicant, request_type)
          return Failure('Invalid Applicant Object') unless payload_entity_applicant.is_a?(AcaEntities::MagiMedicaid::Applicant)
          super(request_type)
        end

        def validate_ssn(applicant)
          encrypted_ssn = applicant.identifying_information.encrypted_ssn
          return Failure("No SSN for applicant") if encrypted_ssn.nil? || encrypted_ssn.empty?
          Operations::Fdsh::EncryptedSsnValidator.new.call(encrypted_ssn)
        end
      end
    end
  end
end