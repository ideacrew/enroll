# frozen_string_literal: true

module Operations
  module Fdsh
    # This class provides a way to validate immigration documents based on their type and required fields using monadic abstractions for error handling and control flow
    class VlpDocumentValidator
      include Dry::Monads[:result, :do, :try]

      REQUIRED_FIELDS = {
        'I-327 (Reentry Permit)' => {
          required: ['alien_number'],
          error_message: 'alien_number Number is required for I-327 (Reentry Permit)'
        },
        'I-551 (Permanent Resident Card)' => {
          required: ['alien_number', 'receipt_number'],
          error_message: 'Alien and Receipt Number are required for I-551 (Permanent Resident Card)'
        },
        'I-571 (Refugee Travel Document)' => {
          required: ['alien_number'],
          error_message: 'Alien Number is required for I-571 (Refugee Travel Document)'
        },
        'I-766 (Employment Authorization Card)' => {
          required: ['alien_number', 'receipt_number'],
          error_message: 'Alien and Receipt Number are required for I-766 (Employment Authorization Card)'
        },
        'Certificate of Citizenship' => {
          required: ['citizenship_number'],
          error_message: 'Citizenship Number is required for Certificate of Citizenship'
        },
        'Naturalization Certificate' => {
          required: ['naturalization_number'],
          error_message: 'Naturalization Number is required for Naturalization Certificate'
        },
        'Machine Readable Immigrant Visa (with Temporary I-551 Language)' => {
          required: ['alien_number', 'passport_number', 'country_of_citizenship'],
          error_message: 'Alien Number, Passport Number, and Three Letter Country of Citizenship are required for Machine Readable Immigrant Visa (with Temporary I-551 Language)'
        },
        'Temporary I-551 Stamp (on passport or I-94)' => {
          required: ['alien_number'],
          error_message: 'Alien Number is required for Temporary I-551 Stamp (on passport or I-94)'
        },
        'I-94 (Arrival/Departure Record)' => {
          required: ['i94_number'],
          error_message: 'I-94 Number is required for I-94 (Arrival/Departure Record)'
        },
        'I-94 (Arrival/Departure Record) in Unexpired Foreign Passport' => {
          required: ['i94_number', 'passport_number', 'country_of_citizenship', 'expiration_date'],
          error_message: 'I-94 Number, Passport Number, Three Letter Country of Citizenship, and Expiration Date are required for I-94 (Arrival/Departure Record) in Unexpired Foreign Passport'
        },
        'Unexpired Foreign Passport' => {
          required: ['passport_number', 'country_of_citizenship', 'expiration_date'],
          error_message: 'Passport Number, Three Letter Country of Citizenship, and Expiration Date are required for Unexpired Foreign Passport'
        },
        'I-20 (Certificate of Eligibility for Nonimmigrant (F-1) Student Status)' => {
          required: ['sevis_id'],
          error_message: 'SEVIS ID is required for I-20 (Certificate of Eligibility for Nonimmigrant (F-1) Student Status)'
        },
        'DS2019 (Certificate of Eligibility for Exchange Visitor (J-1) Status)' => {
          required: ['sevis_id'],
          error_message: 'SEVIS ID is required for DS2019 (Certificate of Eligibility for Exchange Visitor (J-1) Status)'
        },
        'Other (With Alien Number)' => {
          required: ['alien_number', 'subject'],
          error_message: 'Alien Number and Subject are required for Other (With Alien Number)'
        },
        'Other (With I-94 Number)' => {
          required: ['i94_number', 'subject'],
          error_message: 'I-94 Number and Subject are required for Other (With I-94 Number)'
        }
      }.freeze


      def call(document_entity)
        yield validate(document_entity)
        Success('Valid document type')
      end

      private

      def validate(document_entity)
        required_fields = REQUIRED_FIELDS[document_entity.subject]
        return Failure("Invalid document type: #{document_entity.subject}") unless required_fields

        missing_fields = required_fields[:required].reject { |field| document_entity.send(field).present? }
        return Failure("Missing information for document type #{document_entity.subject}: #{missing_fields.join(', ')}") unless missing_fields.empty?

        Success()
      end
    end
  end
end