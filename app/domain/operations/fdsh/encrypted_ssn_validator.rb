# frozen_string_literal: true

require 'aca_entities/operations/encryption/decrypt'

module Operations
  module Fdsh
    # This class is used to validate encrypted ssn
    # Invalid compositions:
    #   All zeros or 000, 666, 900-999 in the area numbers (first three digits);
    #   00 in the group number (fourth and fifth digit); or
    #   0000 in the serial number (last four digits)
    class EncryptedSsnValidator
      include Dry::Monads[:result, :do, :try]

      SSN_FORMAT_REGEX = /^(?!666|000|9\d{2})\d{3}[- ]{0,1}(?!00)\d{2}[- ]{0,1}(?!0{4})\d{4}$/.freeze

      def call(encrypted_ssn)
        decrypted_ssn = yield decrypt_ssn(encrypted_ssn)
        validated_ssn = yield validate_ssn(decrypted_ssn)

        Success(validated_ssn)
      end

      private

      def decrypt_ssn(encrypted_ssn)
        decrypted_ssn = Try do
          AcaEntities::Operations::Encryption::Decrypt.new.call(value: encrypted_ssn).value!
        end.to_result

        if decrypted_ssn.success?
          Success(decrypted_ssn.value!)
        else
          Failure('Failed to decrypt SSN')
        end
      end

      def validate_ssn(ssn)
        if ssn.nil? || ssn.empty?
          Failure('SSN is required')
        elsif SSN_FORMAT_REGEX.match?(ssn)
          Success(ssn)
        else
          Failure('Invalid SSN')
        end
      end
    end
  end
end
