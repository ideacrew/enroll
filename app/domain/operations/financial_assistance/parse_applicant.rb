# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module FinancialAssistance
    # This class constructs financial_assistance_applicant params_hash.
    class ParseApplicant
      include Dry::Monads[:do, :result]

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
        person_attributes(family_member).merge(family_member_id: family_member.id,
                                               is_primary_applicant: family_member.is_primary_applicant,
                                               is_consent_applicant: family_member.is_consent_applicant,
                                               relationship: family_member.relationship)
      end

      def person_attributes(family_member)
        person = family_member.person
        attrs = [:first_name, :last_name, :middle_name, :name_pfx, :name_sfx,
                 :gender, :ethnicity, :tribal_id, :tribal_state, :tribal_name, :tribe_codes, :no_ssn, :is_tobacco_user,
                 :is_homeless, :is_temporarily_out_of_state].inject({}) do |att_hash, attribute|
          att_hash[attribute] = person.send(attribute)
          att_hash
        end
        consumer_role = person.consumer_role
        attrs.merge!(person_hbx_id: person.hbx_id,
                     ssn: person.ssn,
                     dob: person.dob.present? ? person.dob.strftime("%d/%m/%Y") : nil,
                     is_applying_coverage: consumer_role.is_applying_coverage,
                     five_year_bar_applies: consumer_role.five_year_bar_applies,
                     five_year_bar_met: consumer_role.five_year_bar_met,
                     qualified_non_citizen: construct_qualified_non_citizen(consumer_role),
                     citizen_status: person.citizen_status,
                     is_consumer_role: true,
                     same_with_primary: same_with_primary?(family_member),
                     indian_tribe_member: consumer_role.is_tribe_member?,
                     is_incarcerated: person.is_incarcerated,
                     addresses: construct_association_fields(person.addresses),
                     phones: construct_association_fields(person.phones),
                     emails: construct_association_fields(person.emails))

        attrs.merge(vlp_document_params(person.consumer_role))
      end

      def same_with_primary?(family_member)
        return false if family_member.is_primary_applicant?

        family = family_member.family
        dependent = family_member.person
        primary = family.primary_person
        compare_address_keys = ["address_1", "address_2", "city", "state", "zip", "is_homeless", "is_temporarily_out_of_state"]
        compare_address_keys << "county" if EnrollRegistry.feature_enabled?(:display_county)
        result = [dependent, primary].collect{|person| slice_attributes(person, compare_address_keys)}
        result.combination(2).any? do |dependent_arr, primary_arr|
          dependent_arr == primary_arr
        end
      end

      def slice_attributes(person, compare_address_keys)
        [person.attributes.slice(*compare_address_keys), person.home_address&.attributes&.slice(*compare_address_keys)].flatten
      end

      def construct_qualified_non_citizen(consumer_role)
        qnc_code = consumer_role.lawful_presence_determination&.qualified_non_citizenship_result
        case qnc_code
        when 'Y'
          true
        else
          false
        end
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

      def construct_association_fields(records)
        records.collect{|record| record.attributes.symbolize_keys.except(:_id, :created_at, :updated_at, :tracking_version, :full_text, :location_state_code, :modifier_id, :primary) }
      end
    end
  end
end
