# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'aca_entities/magi_medicaid/libraries/iap_library'

module Operations
  module Transformers
    module PersonTo
      # Person params to be transformed.
      class Cv3Person

        include Dry::Monads[:result, :do]
        include Acapi::Notifiers
        require 'securerandom'

        def call(person)
          request_payload = yield construct_payload(person)

          Success(request_payload)
        end

        private


        def construct_payload(person)
          payload = {
            hbx_id: person.hbx_id,
            person_name: construct_person_name(person),
            person_demographics: construct_person_demographics(person),
            person_health: {is_tobacco_user: person.is_tobacco_user,
                            is_physically_disabled: person.is_physically_disabled},
            no_dc_address: person.no_dc_address,
            no_dc_address_reason: person.no_dc_address_reason,
            is_homeless: person.is_homeless,
            is_temporarily_out_of_state: person.is_temporarily_out_of_state,
            age_off_excluded: person.age_off_excluded,
            is_applying_for_assistance: person.is_applying_for_assistance,
            is_active: person.is_active,
            is_disabled: person.is_disabled,
            person_relationships: construct_person_relationships(person.person_relationships),
            consumer_role: nil, # TODO
            resident_role: nil, # TODO
            broker_role: nil, # TODO
            individual_market_transitions: [], #TODO
            verification_types: [], #TODO
            user: transform_user_params(person.user),
            addresses: transform_addresses(person.addresses),
            emails: transform_emails(person.emails),
            phones: transform_phones(person.phones), # TODO
            documents: [], # TODO
            timestamp: {created_at: person.created_at.to_datetime, modified_at: person.updated_at.to_datetime}
          }
          Success(payload)
        end

        def transform_addresses(addresses)
          addresses.collect do |address|
            {
              kind: address.kind,
              address_1: address.address_1,
              address_2: address.address_2,
              address_3: address.address_3,
              city: address.city,
              county: address.county,
              state: address.state,
              zip: address.zip,
              country_name: "United States of America",
              has_fixed_address: address.person.is_homeless ? false : true
            }
          end
        end

        def transform_emails(emails)
          emails.collect { |email| {kind: email.kind, address: email.address}}
        end

        def transform_phones(phones)
          phones.collect do |phone|
            {
              kind: phone.kind,
              country_code: phone.country_code,
              area_code: phone.area_code,
              number: phone.number,
              extension: phone.extension,
              primary: phone.primary,
              full_phone_number: phone.full_phone_number
            }
          end
        end

        def construct_person_name(person)
          {
            first_name: person.first_name,
            middle_name: person.middle_name,
            last_name: person.last_name,
            name_sfx: person.name_sfx,
            name_pfx: person.name_pfx,
            full_name: person.full_name,
            alternate_name: person.alternate_name
          }
        end

        def construct_person_demographics(person)
          {
            ssn: person.ssn,
            no_ssn: person.no_ssn == "0" || person.ssn.present? ? false : true,
            gender: person.gender,
            dob: person.dob,
            date_of_death: person.date_of_death,
            dob_check: person.dob_check,
            is_incarcerated: person.is_incarcerated,
            ethnicity: person.ethnicity,
            race: person.race,
            tribal_id: person.tribal_id,
            language_code: person.language_code || person.user&.preferred_language
          }
        end

        def construct_person_relationships(relationships)
          relationships.collect do |rel|
            relative = rel.relative
            {
              kind: rel.kind,
              relative: {
                hbx_id: relative.hbx_id,
                first_name: relative.first_name,
                middle_name: relative.middle_name,
                last_name: relative.last_name,
                ssn: relative.ssn,
                no_ssn: (relative.no_ssn == "0" || relative.ssn.present?) ? false : true,
                dob: relative.dob,
                gender: relative.gender
              }
            }
          end
        end

        def transform_user_params(user)
          {
            # attestations: construct_attestations,
            approved: user.approved,
            email: user.email,
            oim_id: user.oim_id,
            hint: user.hints,
            identity_confirmed_token: user.identity_confirmed_token,
            identity_final_decision_code: user.identity_final_decision_code,
            identity_final_decision_transaction_id: user.identity_final_decision_transaction_id,
            identity_response_code: user.identity_response_code,
            identity_response_description_text: user.identity_response_description_text,
            identity_verified_date: user.identity_verified_date,
            idp_uuid: user.idp_uuid,
            idp_verified: user.idp_verified,
            last_portal_visited: user.last_portal_visited,
            preferred_language: user.preferred_language,
            profile_type: user.profile_type,
            roles: user.roles,
            timestamps: {created_at: user.created_at.to_datetime, modified_at: user.updated_at.to_datetime}
          }
        end
      end
    end
  end
end
