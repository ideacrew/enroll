# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Notices
    # IVL open enrollment reverification notice
    class IvlOeReverificationTrigger
      include Dry::Monads[:result, :do]
      include EventSource::Command
      include EventSource::Logging

      # @param [Family] family object (required)
      # @return [Dry::Monads::Result]

      def call(params)
        _values = yield validate(params)
        event_name = yield determine_event_name(params[:family])
        payload = yield build_payload(params[:family])
        event = yield build_event(payload, event_name)
        result = yield publish_response(event)

        Success(result)
      end

      private

      def validate(params)
        return Failure('Missing Family') if params[:family].blank?

        Success(params)
      end

      def fetch_application(family)
        applications = ::FinancialAssistance::Application.where(family_id: family.id, assistance_year: TimeKeeper.date_of_record.next_year.year)

        determined_applications = applications.where(aasm_state: 'determined')
        return determined_applications.max_by(&:created_at) if determined_applications.present?

        applications.max_by(&:created_at)
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      def determine_event_name(family)
        financial_application = fetch_application(family)

        return Success('qhp_eligible_on_reverification') if financial_application.nil?

        applicants = financial_application.applicants

        event_name =
          if applicants.all?(&:is_ia_eligible)
            'aqhp_eligible_on_reverification'
          elsif applicants.all? { |applicant| applicant.is_medicaid_chip_eligible || applicant.is_magi_medicaid }
            'medicaid_eligible_on_reverification'
          elsif applicants.all?(&:is_without_assistance)
            'uqhp_eligible_on_reverification'
          end

        event_name.present? ? Success(event_name) : Failure("Unable to determine event for the given family id: #{family.id}")
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      def build_addresses(person)
        address = person.mailing_address
        [
          {
            :kind => address.kind,
            :address_1 => address.address_1,
            :address_2 => address.address_2,
            :address_3 => address.address_3,
            :state => address.state,
            :city => address.city,
            :zip => address.zip
          }
        ]
      end

      def update_and_build_verification_types(person)
        person.consumer_role.types_include_to_notices.collect do |verification_type|
          {
            type_name: verification_type.type_name,
            validation_status: verification_type.validation_status,
            due_date: verification_type.due_date
          }
        end
      end

      def build_family_member_hash(family)
        family.family_members.collect do |fm|
          person = fm.person
          outstanding_verification_types = person.consumer_role.types_include_to_notices
          member_hash = {
            is_primary_applicant: fm.is_primary_applicant,
            person: {
              hbx_id: person.hbx_id,
              person_name: { first_name: person.first_name, last_name: person.last_name },
              person_demographics: { gender: person.gender, dob: person.dob, is_incarcerated: person.is_incarcerated || false },
              person_health: { is_tobacco_user: person.is_tobacco_user },
              is_active: person.is_active,
              is_disabled: person.is_disabled,
              addresses: build_addresses(person)
            }
          }
          member_hash[:person].merge!(verification_types: update_and_build_verification_types(person)) if outstanding_verification_types.present?
          member_hash
        end
      end

      def build_household_hash(family)
        family.households.collect do |household|
          {
            start_date: household.effective_starting_on,
            is_active: household.is_active,
            coverage_households: household.coverage_households.collect { |ch| {is_immediate_family: ch.is_immediate_family, coverage_household_members: ch.coverage_household_members.collect {|chm| {is_subscriber: chm.is_subscriber}}} }
          }
        end
      end

      def documents_needed?(family)
        family.family_members.any? { |member| member.person.consumer_role.types_include_to_notices.present? }
      end

      def build_family_payload(family)
        payload = { family_members: build_family_member_hash(family), households: build_household_hash(family), hbx_id: family.hbx_assigned_id.to_s, documents_needed: documents_needed?(family) }
        family_contract = AcaEntities::Contracts::Families::FamilyContract.new.call(payload)
        return Failure("invalid payload for family id: #{family.id}") unless family_contract.success?

        family_entity = AcaEntities::Families::Family.new(family_contract.to_h)

        Success(family_entity)
      end

      def build_payload(family)
        financial_application = fetch_application(family)

        entity =
          if financial_application.present? && financial_application.eligibility_response_payload.present?
            ::AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(
              JSON.parse(financial_application.eligibility_response_payload, :symbolize_name => true)
            )
          else
            build_family_payload(family)
          end

        if entity&.success?
          Success(entity.success.to_h)
        else
          Failure("Error parsing the payload for the given family id: #{family.id}")
        end
      end

      def build_event(payload, event_name)
        result = event("events.individual.notices.#{event_name}", attributes: payload)
        unless Rails.env.test?
          logger.info('-' * 100)
          logger.info(
            "Enroll Reponse Publisher to external systems(polypress),
            event_key: events.individual.notices.#{event_name}, attributes: #{payload.to_h}, result: #{result}"
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
