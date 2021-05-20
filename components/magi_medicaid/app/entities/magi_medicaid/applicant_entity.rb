# frozen_string_literal: true

module MagiMedicaid
  class ApplicantEntity < Dry::Struct

    attribute :name, MagiMedicaid::PersonNameEntity
    attribute :identity_information, MagiMedicaid::IdentityInformationEntity
    attribute :demographic, MagiMedicaid::DemographicEntity
    attribute :attestation, MagiMedicaid::AttestationEntity
    attribute :native_american_information, MagiMedicaid::NativeAmericanInformationEntity
    attribute :citizenship_immigration_status_information, MagiMedicaid::CitizenshipImmigrationStatusInformationEntity
    attribute :vlp_document, MagiMedicaid::VlpDocumentEntity

    attribute :is_primary_applicant, Types::Strict::Bool.meta(omittable: true)
    attribute :family_member_id, Types::Bson.optional.meta(omittable: true)
    attribute :person_hbx_id, Types::String.optional.meta(omittable: true)

    attribute :language_code, Types::String.optional.meta(omittable: true)
    attribute :no_dc_address, Types::Strict::Bool.meta(omittable: true)
    attribute :is_homeless, Types::Strict::Bool.meta(omittable: true)
    attribute :is_temporarily_out_of_state, Types::Strict::Bool.meta(omittable: true)

    attribute :is_consumer_role, Types::Strict::Bool
    attribute :is_resident_role, Types::Strict::Bool.meta(omittable: true)
    attribute :vlp_document_id, Types::String.optional.meta(omittable: true)
    attribute :same_with_primary, Types::Bool.optional.meta(omittable: true)
    attribute :is_applying_coverage, Types::Strict::Bool

    attribute :addresses, Types::Array.of(MagiMedicaid::AddressEntity)
    attribute :emails, Types::Array.of(MagiMedicaid::EmailEntity)
    attribute :phones, Types::Array.of(MagiMedicaid::PhoneEntity)
  end
end
