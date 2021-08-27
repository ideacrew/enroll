# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    # Class for publishing the results of updated families to Sugar CRM, if enabled
    class PublishFamily
      send(:include, Dry::Monads[:result, :do])
      include EventSource::Command

      # Update this constant with new events that are added/registered in ::Publishers::FamilyPublisher
      REGISTERED_EVENTS = %w[family_update].freeze

      # @param [ Family] instance fo family
      # @return Success rersult

      def call(family)
        payload = yield construct_payload_hash(family)
        event = yield build_event(payload)
        result = yield publish(event, payload)
        Success(result)
      end

      private

      def build_event(payload)
        result = event('events.crm_gateway.families.family_update', attributes: payload)
        unless Rails.env.test?
          logger.info('-' * 100)
          logger.info(
            "Enroll Reponse Publisher to external systems(crm_gateway),
            event_key: events.crm_gateway.families.family_update, attributes: #{payload.to_h}, result: #{result}"
          )
          logger.info('-' * 100)
        end
        result
      end

      def construct_payload_hash(family)
        if family.is_a?(::Family)
          Operations::Transformers::FamilyTo::Cv3Family.new.call(family)
        else
          Failure("Invalid Family Object #{family}")
        end
      end

      def publish(event)
        event.publish
        Success("Successfully published the payload for event: family_update")
      end
    end
  end
end
