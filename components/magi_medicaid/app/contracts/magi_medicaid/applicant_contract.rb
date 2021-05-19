# frozen_string_literal: true

  module MagiMedicaid
    class ApplicantContract < Dry::Validation::Contract

      params do
        required(:name).maybe(:hash)
        required(:identity_information).maybe(:hash)
        required(:demographic).maybe(:hash)
        required(:attestation).maybe(:hash)
        required(:native_american_information).maybe(:hash)
        required(:citizenship_immigration_status_information).maybe(:hash)
        required(:vlp_document).maybe(:hash)

        optional(:is_primary_applicant).maybe(:bool)
        optional(:person_hbx_id).maybe(:string)
        optional(:family_member_id).maybe(Types::Bson)

        optional(:language_code).maybe(:string)
        optional(:no_dc_address).filled(:bool)
        optional(:is_homeless).maybe(:bool)
        optional(:is_temporarily_out_of_state).maybe(:bool)

        required(:is_consumer_role).filled(:bool)
        optional(:same_with_primary).maybe(:bool)
        required(:is_applying_coverage).filled(:bool)

        optional(:addresses).maybe(:array)
        optional(:phones).maybe(:array)
        optional(:emails).maybe(:array)
      end

      rule(:name) do
        if key? && value
          if value.is_a?(Hash)
            result = ::MagiMedicaid::PersonNameContract.new.call(value)
            key.failure(text: "invalid applicant name", error: result.errors.to_h) if result&.failure?
          else
            key.failure(text: "Expected Person Name hash")
          end
        end
      end

      rule(:identity_information) do
        if key? && value
          if value.is_a?(Hash)
            result = ::MagiMedicaid::IdentityInformationContract.new.call(value)
            key.failure(text: "invalid  identity information", error: result.errors.to_h) if result&.failure?
          else
            key.failure(text: "Expected identity information hash")
          end
        end
      end

      rule(:demographic) do
        if key? && value
          if value.is_a?(Hash)
            result = ::MagiMedicaid::DemographicContract.new.call(value)
            key.failure(text: "invalid demographic information", error: result.errors.to_h) if result&.failure?
          else
            key.failure(text: "Expected demographic information hash")
          end
        end
      end

      rule(:attestation) do
        if key? && value
          if value.is_a?(Hash)
            result = ::MagiMedicaid::AttestationContract.new.call(value)
            key.failure(text: "invalid attestation information", error: result.errors.to_h) if result&.failure?
          else
            key.failure(text: "Expected attestation information hash")
          end
        end
      end

      rule(:native_american_information) do
        if key? && value
          if value.is_a?(Hash)
            result = ::MagiMedicaid::NativeAmericanInformationContract.new.call(value)
            key.failure(text: "invalid native american information", error: result.errors.to_h) if result&.failure?
          else
            key.failure(text: "Expected native american information hash")
          end
        end
      end

      rule(:citizenship_immigration_status_information) do
        if key? && value
          if value.is_a?(Hash)
            result = ::MagiMedicaid::CitizenshipImmigrationStatusInformationContract.new.call(value)
            key.failure(text: "invalid citizenship immigration status information", error: result.errors.to_h) if result&.failure?
          else
            key.failure(text: "Expected citizenship immigration status information hash")
          end
        end
      end

      rule(:vlp_document) do
        if key? && value
          if value.is_a?(Hash)
            result = ::MagiMedicaid::VlpDocumentContract.new.call(value)
            key.failure(text: "invalid vlp document information", error: result.errors.to_h) if result&.failure?
          else
            key.failure(text: "Expected vlp document information hash")
          end
        end
      end

      rule(:addresses).each do
        if key? && value
          if value.is_a?(Hash)
            result = ::MagiMedicaid::AddressContract.new.call(value)
            key.failure(text: "invalid address", error: result.errors.to_h) if result&.failure?
          else
            key.failure(text: "invalid addresses. Expected a hash.")
          end
        end
      end

      rule(:is_primary_applicant) do
        if key? && value
          if value
            key.failure(text: "family_member_id should be present") if values[:family_member_id].blank?
            key.failure(text: "person hbx id should be present") if values[:person_hbx_id].blank?
          end
        end
      end

      rule(:phones).each do
        if key? && value
          if value.is_a?(Hash)
            result = ::MagiMedicaid::PhoneContract.new.call(value)
            key.failure(text: "invalid phone", error: result.errors.to_h) if result&.failure?
          else
            key.failure(text: "invalid phones. Expected a hash.")
          end
        end
      end

      rule(:emails).each do
        if key? && value
          if value.is_a?(Hash)
            result = ::MagiMedicaid::EmailContract.new.call(value)
            key.failure(text: "invalid email", error: result.errors.to_h) if result&.failure?
          else
            key.failure(text: "invalid emails. Expected a hash.")
          end
        end
      end
    end
  end