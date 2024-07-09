# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'aca_entities/magi_medicaid/libraries/iap_library'

# rubocop:disable Metrics/ClassLength
module Operations
  module Transformers
    module PersonTo
      # Person params to be transformed.
      class Cv3Person
        include Rails.application.routes.url_helpers
        include Dry::Monads[:do, :result]

        def call(person)
          request_payload = yield construct_payload(person)

          Success(request_payload)
        end

        private

        def construct_payload(person)
          payload = {
            person_id: person.id.to_s,
            external_person_link: resume_enrollment_exchanges_agents_url(person_id: person.id.to_s),
            hbx_id: person.hbx_id.to_s,
            person_name: construct_person_name(person),
            person_demographics: construct_person_demographics(person),
            person_health: transform_person_health(person),
            no_dc_address: person.no_dc_address,
            no_dc_address_reason: person.no_dc_address_reason,
            is_homeless: person.is_homeless,
            is_temporarily_out_of_state: person.is_temporarily_out_of_state,
            age_off_excluded: person.age_off_excluded,
            is_applying_for_assistance: person.is_applying_for_assistance,
            is_active: person.is_active,
            is_disabled: person.is_disabled,
            person_relationships: construct_person_relationships(person.person_relationships),
            consumer_role: construct_consumer_role(person.consumer_role),
            resident_role: construct_resident_role(person.resident_role),
            individual_market_transitions: transform_individual_market_transitions(person.individual_market_transitions),
            verification_types: transform_verification_types(person.verification_types),
            user: transform_user_params(person.user),
            addresses: transform_addresses(person.addresses),
            emails: transform_emails(person.emails),
            phones: transform_phones(person.phones),
            documents: transform_documents(person.documents),
            timestamp: {created_at: person.created_at.to_datetime, modified_at: person.updated_at.to_datetime}
          }
          Success(payload)
        rescue StandardError => e
          Failure("Cv3Person hbx id: #{person&.hbx_id} | exception: #{e.inspect} | backtrace: #{e.backtrace.inspect}")
        end

        def transform_person_health(person)
          ph_hash = { is_physically_disabled: person.is_physically_disabled }
          ph_hash.merge!(is_tobacco_user: person.is_tobacco_user) if person.is_tobacco_user.present?
          ph_hash
        end

        def transform_consumer_role(consumer_role)
          return nil unless consumer_role

          consumer_role.serializable_hash.deep_symbolize_keys
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

        def transform_documents(documents)
          documents.collect do |document|
            {
              title: document.title,
              creator: document.creator,
              subject: document.subject,
              description: document.description,
              publisher: document.publisher,
              contributor: document.contributor,
              date: document.date,
              type: document.type,
              format: document.format,
              identifier: document.identifier,
              source: document.source,
              language: document.language,
              relation: document.relation,
              coverage: document.coverage,
              rights: document.rights,
              tags: document.tags,
              size: document.size,
              doc_identifier: document.doc_identifier
            }
          end
        end

        def transform_verification_types(verification_types)
          verification_types.collect do |verification_type|
            {
              type_name: verification_type.type_name,
              validation_status: verification_type.validation_status,
              applied_roles: verification_type.applied_roles,
              update_reason: verification_type.update_reason,
              rejected: verification_type.rejected,
              external_service: verification_type.external_service,
              due_date: verification_type.verif_due_date,
              due_date_type: verification_type.due_date_type,
              # TO DO updated_by:,
              inactive: verification_type.inactive,
              vlp_documents: transform_vlp_documents(verification_type.vlp_documents)
            }
          end
        end

        def construct_updated_by(updated_by); end

        def transform_vlp_documents(vlp_documents)
          vlp_documents.collect do |vlp_document|
            next if vlp_document.subject.nil?
            {
              subject: vlp_document.subject,
              description: vlp_document.description,
              alien_number: vlp_document.alien_number,
              i94_number: vlp_document.i94_number,
              visa_number: vlp_document.visa_number,
              passport_number: vlp_document.passport_number,
              sevis_id: vlp_document.sevis_id,
              naturalization_number: vlp_document.naturalization_number,
              receipt_number: vlp_document.receipt_number,
              citizenship_number: vlp_document.citizenship_number,
              card_number: vlp_document.card_number,
              country_of_citizenship: vlp_document.country_of_citizenship,
              expiration_date: vlp_document.expiration_date,
              issuing_country: vlp_document.issuing_country
            }
          end
        end

        def transform_ridp_documents(ridp_documents)
          ridp_documents.collect do |document|
            ridp_documents_hash = {
              status: document.status,
              ridp_verification_type: document.ridp_verification_type,
              comment: document.comment
            }
            ridp_documents_hash.merge!(uploaded_at: document.uploaded_at) if document.uploaded_at.present?
            ridp_documents_hash
          end
        end

        def transform_individual_market_transitions(individual_market_transitions)
          individual_market_transitions.collect do |transition|
            {
              role_type: transition.role_type,
              start_on: transition.effective_starting_on,
              end_on: transition.effective_ending_on,
              reason_code: transition.reason_code,
              submitted_at: transition.submitted_at
            }
          end
        end

        def construct_resident_role(resident_role)
          return if resident_role.nil?
          residency_determined_at = resident_role.residency_determined_at
          result = {
            is_applicant: resident_role.is_applicant,
            is_active: resident_role.is_active,
            is_state_resident: resident_role.is_state_resident,
            contact_method: resident_role.contact_method,
            language_preference: resident_role.language_preference,
            local_residency_responses: resident_role.local_residency_responses,
            lawful_presence_determination: construct_lawful_presence_determination(resident_role.lawful_presence_determination)
          }
          # only include residency_determined_at key if value is present in order to pass ResidentRoleContract fvalidations
          result.merge!(residency_determined_at: residency_determined_at) if residency_determined_at.present?
          result
        end

        def construct_consumer_role(consumer_role)
          return if consumer_role.nil?
          {
            five_year_bar: consumer_role.five_year_bar,
            requested_coverage_start_date: consumer_role.requested_coverage_start_date,
            aasm_state: consumer_role.aasm_state,
            is_applicant: consumer_role.is_applicant,
            birth_location: consumer_role.birth_location,
            marital_status: consumer_role.marital_status,
            is_active: consumer_role.is_active,
            is_applying_coverage: consumer_role.is_applying_coverage,
            bookmark_url: consumer_role.bookmark_url,
            admin_bookmark_url: consumer_role.admin_bookmark_url,
            contact_method: consumer_role.contact_method,
            language_preference: consumer_role.language_preference,
            is_state_resident: consumer_role.is_state_resident,
            identity_validation: consumer_role.identity_validation,
            identity_update_reason: consumer_role.identity_update_reason,
            application_validation: consumer_role.application_validation,
            application_update_reason: consumer_role.application_update_reason,
            identity_rejected: consumer_role.identity_rejected,
            application_rejected: consumer_role.application_rejected,
            documents: transform_documents(consumer_role.documents),
            vlp_documents: transform_vlp_documents([consumer_role.active_vlp_document].compact),
            ridp_documents: transform_ridp_documents(consumer_role.ridp_documents),
            verification_type_history_elements: transform_verification_type_history_elements(consumer_role.verification_type_history_elements),
            lawful_presence_determination: construct_lawful_presence_determination(consumer_role.lawful_presence_determination),
            local_residency_responses: transform_event_responses(consumer_role.local_residency_responses),
            local_residency_requests: transform_event_requests(consumer_role.local_residency_requests)
          }
        end

        def transform_verification_type_history_elements(elements)
          elements.collect do |element|
            {
              verification_type: element.verification_type,
              action: element.action,
              modifier: element.modifier,
              update_reason: element.update_reason
            }
          end
        end

        def construct_lawful_presence_determination(lawful_presence_determination)
          return if lawful_presence_determination.nil?
          {
            vlp_verified_at: lawful_presence_determination.vlp_verified_at,
            vlp_authority: lawful_presence_determination.vlp_authority,
            vlp_document_id: lawful_presence_determination.vlp_document_id,
            citizen_status: lawful_presence_determination.citizen_status,
            citizenship_result: lawful_presence_determination.citizenship_result,
            qualified_non_citizenship_result: lawful_presence_determination.qualified_non_citizenship_result,
            aasm_state: lawful_presence_determination.aasm_state,
            ssa_responses: transform_event_responses(lawful_presence_determination.ssa_responses),
            ssa_requests: transform_event_requests(lawful_presence_determination.ssa_requests),
            vlp_responses: transform_event_responses(lawful_presence_determination.vlp_responses),
            vlp_requests: transform_event_requests(lawful_presence_determination.vlp_requests)
          }
        end

        def transform_event_responses(responses)
          responses.collect do |response|
            construct_event_response(response)
          end
        end

        def construct_event_response(response)
          return if response.nil?
          {
            received_at: response.received_at,
            body: response.body
          }
        end

        def transform_event_requests(requests)
          requests.collect do |request|
            construct_event_request(request)
          end
        end

        def construct_event_request(request)
          return if request.nil?
          {
            requested_at: request.requested_at,
            body: request.body
          }
        end

        def construct_person_name(person)
          return if person.nil?

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
          # is_incarcerated field is nil when person is NOT applying for coverage but is required in cv3 contract
          is_incarcerated = person.is_incarcerated || false
          {
            encrypted_ssn: encrypt(person.ssn),
            no_ssn: person.no_ssn == "0" || person.ssn.present? ? false : true,
            gender: person.gender,
            dob: person.dob,
            date_of_death: person.date_of_death,
            dob_check: person.dob_check,
            is_incarcerated: is_incarcerated,
            ethnicity: person.ethnicity,
            race: person.race,
            tribal_id: person.tribal_id,
            language_code: person.language_code || person.user&.preferred_language || 'en',
            alive_status: construct_alive_status(person)
          }
        end

        def construct_alive_status(person)
          demographics_group = person.demographics_group
          return {} unless demographics_group&.alive_status

          alive_status = demographics_group.alive_status
          {
            is_deceased: alive_status.is_deceased,
            date_of_death: alive_status.date_of_death
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
                encrypted_ssn: encrypt(relative.ssn),
                no_ssn: (relative.no_ssn == "0" || relative.ssn.present?) ? false : true,
                dob: relative.dob,
                gender: relative.gender,
                relationship_to_primary: rel.kind
              }
            }
          end
        end

        def transform_user_params(user)
          return {} unless user.present?

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

        def encrypt(value)
          return nil unless value

          AcaEntities::Operations::Encryption::Encrypt.new.call({value: value}).value!
        end
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
