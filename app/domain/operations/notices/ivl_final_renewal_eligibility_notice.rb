# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Notices
    # IVL Final Renewal Eligibility Notice
    class IvlFinalRenewalEligibilityNotice
      include Dry::Monads[:do, :result]
      include EventSource::Command
      include EventSource::Logging
      include ActionView::Helpers::NumberHelper

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

      def enrollments(family)
        query = {
          effective_on: effective_on,
          :aasm_state => 'auto_renewing'
        }
        family.active_household.hbx_enrollments.where(query)
      end

      def effective_on
        TimeKeeper.date_of_record.next_year.beginning_of_year
      end

      def validate(params)
        family = params[:family]
        return Failure('Missing Family') if family.blank?
        return Failure("Family does not have #{effective_on} auto_renewing enrollments") unless enrollments(family).present?

        Success(params)
      end

      def build_payload(family)
        result = Operations::Transformers::FamilyTo::Cv3Family.new.call(family)
        return result unless result.success?

        family_hash = update_issuer_phone_format(result.value!)
        Success(family_hash)
      end

      def update_issuer_phone_format(family_hash)
        family_hash[:households].each do |household|
          household[:hbx_enrollments].each do |hbx_enrollment|
            hbx_enrollment[:issuer_profile_reference][:phone] = number_to_phone(hbx_enrollment[:issuer_profile_reference][:phone], area_code: true)
          end
        end
        family_hash
      end

      def validate_payload(payload)
        result = AcaEntities::Contracts::Families::FamilyContract.new.call(payload)

        return Failure('invalid payload') unless result.success?
        Success(result.to_h)
      end

      def through_entity(payload)
        Success(AcaEntities::Families::Family.new(payload).to_h)
      end

      def build_event(payload)
        result = event('events.individual.notices.final_renewal_eligibility_determined', attributes: payload)
        unless Rails.env.test?
          logger.info('-' * 100)
          logger.info(
            "Enroll Reponse Publisher to external systems(polypress),
            event_key: events.individual.notices.final_renewal_eligibility_determined, attributes: #{payload.to_h}, result: #{result}"
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
