# frozen_string_literal: true

module Operations
  module Fdsh
    module PayloadEligibility
    # This class defines a set of validation rules for different types of eligibility requests.
    # The process method calls each validation rule for the given request type and returns a Success result if all rules pass, or a Failure result if any rule fails.
      class CheckPersonEligibilityRules < CheckBaseEligibilityRules

        private

        def validate(payload_entity, request_type)
          return Failure("Invalid Person Object #{payload_entity}") unless payload_entity.is_a?(::AcaEntities::People::Person)
          super(request_type)
        end

        def validate_ssn(payload)
          encrypted_ssn = payload.person_demographics.encrypted_ssn || payload.person_identifying_information.encrypted_ssn
          return Failure('No SSN for member') if encrypted_ssn.nil? || encrypted_ssn.empty?
          Operations::Fdsh::EncryptedSsnValidator.new.call(encrypted_ssn)
        end

        def validate_dhs_document(payload)
          payload.consumer_role.vlp_documents.map do |document|
            Operations::Fdsh::VlpDocumentTypeValidator.new.call(document)
          end
        end
      end
    end
  end
end