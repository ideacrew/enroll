# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module MagiMedicaid
    # This class constructs financial_assistance_applicant params_hash.
    class ParseApplicant
      include Dry::Monads[:result, :do]

      # @param [ FamilyMember ] family_member
      # @return [ Ruby Hash ] Applicant
      def call(params)
        values              = yield validate(params)
        applicant_hash      = yield parse_family_member(values)

        Success(applicant_hash)
      end

      private

      def validate(params)
        return Failure('Given family member is not a valid object') unless params[:family_member].is_a?(::FamilyMember)

        Failure('Given family member does not have a matching person') unless params[:family_member].person.present?

        Success(params)
      end

      def parse_family_member(values)
        Success(family_member_attributes(values[:family_member]))
      end

      def family_member_attributes(family_member)
        person_attributes(family_member.person).merge(family_member_id: family_member.id,
                                                      is_primary_applicant: family_member.is_primary_applicant,
                                                      is_consent_applicant: family_member.is_consent_applicant)
      end

      def person_attributes(person)
        attrs = [:is_tobacco_user,
                 :is_homeless, :is_temporarily_out_of_state].inject({}) do |att_hash, attribute|
          att_hash[attribute] = person.send(attribute)
          att_hash
        end
        attrs.merge!(name: construct_person_name_fields(person),
                     identity_information: construct_identity_information_fields(person),
                     demographic: construct_demographic_fields(person),
                     attestation: construct_attestation_fields(person),
                     native_american_information: construct_native_american_information_fields(person),
                     citizenship_immigration_status_information: construct_status_info_fields(person.consumer_role.lawful_presence_determination),
                     vlp_document: vlp_document_params(person.consumer_role),
                     person_hbx_id: person.hbx_id,
                     is_applying_coverage: person.consumer_role.is_applying_coverage,
                     is_consumer_role: true,
                     same_with_primary: false,
                     addresses: construct_association_fields(person.addresses),
                     phones: construct_association_fields(person.phones),
                     emails: construct_association_fields(person.emails))
      end

      def vlp_document_params(consumer_role)
        return {} unless consumer_role.active_vlp_document
        vlp_object = consumer_role.active_vlp_document
        vlp_attrs = vlp_object.attributes.symbolize_keys.slice(:alien_number,
                                                               :i94_number,
                                                               :visa_number,
                                                               :passport_number,
                                                               :sevis_id,
                                                               :naturalization_number,
                                                               :receipt_number,
                                                               :citizenship_number,
                                                               :card_number,
                                                               :country_of_citizenship,
                                                               :expiration_date,
                                                               :issuing_country)
        vlp_attrs.merge!({expiration_date: vlp_attrs[:expiration_date].strftime("%d/%m/%Y")}) if vlp_attrs[:expiration_date].present?
        vlp_attrs.merge!({vlp_subject: vlp_object[:subject], vlp_description: vlp_object[:description]})
        vlp_attrs
      end

      def construct_person_name_fields(person)
        person.attributes.symbolize_keys.slice(:name_pfx, :first_name, :middle_name, :last_name, :name_sfx)
      end

      def construct_identity_information_fields(person)
        person.attributes.symbolize_keys.slice(:encrypted_ssn, :no_ssn)
      end

      def construct_demographic_fields(person)
        demographic_params = person.attributes.symbolize_keys.slice(:gender, :ethnicity, :race)
        demographic_params.merge!(:dob => person.dob.to_date)
        demographic_params
      end

      def construct_attestation_fields(person)
        person.attributes.symbolize_keys.slice(:is_incarcerated, :is_disabled)
      end

      def construct_native_american_information_fields(person)
        person.attributes.symbolize_keys.slice(:indian_tribe_member, :tribal_id)
      end

      def construct_status_info_fields(lawful_presence_determination)
        lawful_presence_determination.attributes.symbolize_keys.slice(:citizen_status)
      end

      def construct_association_fields(records)
        records.collect{|record| record.attributes.symbolize_keys.except(:_id, :created_at, :updated_at, :tracking_version, :full_text, :location_state_code, :modifier_id, :primary) }
      end
    end
  end
end
