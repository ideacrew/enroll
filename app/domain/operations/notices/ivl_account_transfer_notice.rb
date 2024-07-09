# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Notices
    # IVL Account Transfer Notice
    class IvlAccountTransferNotice
      include Dry::Monads[:do, :result]
      include EventSource::Command
      include EventSource::Logging

      # @param [Family] :family Family
      # @return [Dry::Monads::Result]
      def call(params)
        values = yield validate(params)
        payload = yield build_payload(values[:family])
        validated_payload = yield validate_payload(payload)
        entity_result = yield through_entity(validated_payload)
        event = yield build_event(entity_result)
        result = yield publish_response(event)

        Success(result)
      end

      private

      def validate(params)
        return Failure('Missing family') if params[:family].blank?

        Success(params)
      end

      def build_addresses(person)
        person.addresses.collect do |address|
          {
            kind: address.kind,
            address_1: address.address_1.presence,
            address_2: address.address_2.presence,
            address_3: address.address_3.presence,
            state: address.state,
            city: address.city,
            zip: address.zip
          }
        end
      end

      def build_consumer_role(consumer_role)
        {
          is_applying_coverage: consumer_role.is_applying_coverage,
          contact_method: consumer_role.contact_method,
          five_year_bar: consumer_role.five_year_bar,
          requested_coverage_start_date: consumer_role.requested_coverage_start_date,
          aasm_state: consumer_role.aasm_state,
          is_applicant: consumer_role.is_applicant,
          is_state_resident: consumer_role.is_state_resident,
          identity_validation: consumer_role.identity_validation,
          identity_update_reason: consumer_role.identity_update_reason,
          application_validation: consumer_role.application_validation,
          application_update_reason: consumer_role.application_update_reason,
          identity_rejected: consumer_role.identity_rejected,
          application_rejected: consumer_role.application_rejected,
          lawful_presence_determination: {}
        }
      end

      def build_family_members_hash(family)
        family.family_members.collect do |fm|
          person = fm.person
          {
            is_primary_applicant: fm.is_primary_applicant,
            person: {
              hbx_id: person.hbx_id,
              person_name: { first_name: person.first_name, last_name: person.last_name },
              person_demographics: { ssn: person.ssn, gender: person.gender, dob: person.dob, is_incarcerated: person.is_incarcerated || false },
              person_health: { is_tobacco_user: person.is_tobacco_user },
              is_active: person.is_active,
              is_disabled: person.is_disabled,
              consumer_role: build_consumer_role(person.consumer_role),
              addresses: build_addresses(person)
            }
          }.with_indifferent_access
        end
      end

      def build_payload(family)
        family_hash = {
          family_members: build_family_members_hash(family),
          hbx_id: family.hbx_assigned_id.to_s
        }.with_indifferent_access

        Success(family_hash)
      rescue StandardError => e
        Failure("Unable to build payload for family id: #{family.id} due to #{e.inspect}")
      end

      def validate_payload(payload)
        result = AcaEntities::Contracts::Families::FamilyContract.new.call(payload)

        return Failure("unable to validate payload for family_hbx_id: #{payload[:hbx_id]}") unless result.success?
        Success(result.to_h)
      end

      def through_entity(payload)
        Success(AcaEntities::Families::Family.new(payload).to_h)
      end

      def build_event(payload)
        result = event('events.individual.notices.account_transferred', attributes: payload)
        unless Rails.env.test?
          logger.info('-' * 100)
          logger.info(
            "Enroll Reponse Publisher to external systems(polypress),
            event_key: events.individual.notices.account_transferred, attributes: #{payload.to_h}, result: #{result}"
          )
          logger.info('-' * 100)
        end
        result
      end

      def publish_response(event)
        Success(event.publish)
      end
    end
  end
end
