# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Notices
    # IVL Account Transfer Notice
    class IvlAccountTransferNotice
      include Dry::Monads[:result, :do]
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

      def build_payload(family)
        result = Operations::Transformers::FamilyTo::Cv3Family.new.call(family)
        return result unless result.success?

        Success(result.value!)
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
