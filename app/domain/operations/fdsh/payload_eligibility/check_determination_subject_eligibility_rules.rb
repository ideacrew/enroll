# frozen_string_literal: true

# This module defines operations related to FDSH payload eligibility.
module Operations
  module Fdsh
    module PayloadEligibility
      # This class checks the eligibility rules for a determination subject within the FDSH payload.
      # It extends `CheckBaseEligibilityRules` to leverage common eligibility rule checks.
      class CheckDeterminationSubjectEligibilityRules < CheckBaseEligibilityRules
        # Valid eligibility states for health and dental product enrollments.
        VALID_ELIGIBLITY_STATES = [
          'health_product_enrollment_status',
          'dental_product_enrollment_status'
        ].freeze

        private

        # Validates the payload entity to ensure it is a valid Subject object and then
        # calls the superclass's validate method.
        #
        # @param payload_entity [AcaEntities::Eligibilities::Subject] The subject entity to validate.
        # @param request_type [Symbol] The type of request being validated.
        # @return [Dry::Monads::Result] Success or Failure indicating the validation result.
        def validate(payload_entity, request_type)
          return Failure("Invalid Subject Object #{payload_entity}") unless payload_entity.is_a?(Hash)
          super(request_type)
        end

        # Validates the Social Security Number (SSN) of the payload entity.
        #
        # @param payload_entity [AcaEntities::Eligibilities::Subject] The subject entity whose SSN is to be validated.
        # @return [Dry::Monads::Result] Success or Failure indicating the validation result of the SSN.
        def validate_ssn(payload_entity)
          encrypted_ssn = payload_entity[:encrypted_ssn]
          return Failure("No SSN for member #{payload_entity[:hbx_id]}") if encrypted_ssn.nil? || encrypted_ssn.empty?

          AcaEntities::Operations::EncryptedSsnValidator.new.call(encrypted_ssn)
        end

        # Checks if the member is enrolled based on the eligibility states provided in the payload.
        #
        # @param payload_entity [AcaEntities::Eligibilities::Subject] The subject entity to check enrollment status for.
        # @return [Dry::Monads::Result] Success if the subject is enrolled in either health or dental enrollment,
        #   otherwise Failure.
        def is_member_enrolled?(payload_entity)
          states = payload_entity[:eligibility_states].collect { |k, v| v[:is_eligible] if VALID_ELIGIBLITY_STATES.include?(k.to_s) }.flatten.compact

          return Failure("No states found for the given subject/member hbx_id: #{payload_entity[:hbx_id]} ") unless states.present?
          return Success() if states.any?(true)

          Failure("subject is not enrolled in health or dental enrollment")
        end
      end
    end
  end
end