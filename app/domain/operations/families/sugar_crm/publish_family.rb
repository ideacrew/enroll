# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    # Class for publishing the results of updated families to Sugar CRM, if enabled
    class PublishFamily
      send(:include, Dry::Monads[:result, :do])

      # Update this constant with new events that are added/registered in ::Publishers::FamilyPublisher
      REGISTERED_EVENTS = %w[family_update].freeze

      # @param [ Family] instance fo family
      # @return Success rersult

      def call(family)
        payload = yield transform_family_and_family_members(family)
        event = yield build_event(payload)
        result = yield publish(event, payload)
        Success(result)
      end

      private
      
      # I guess convert payload to XML to send?
      def initialize_family_payload(family)
        payload = {}
        payload[:family] = family.attributes
        payload[:family_members] = []
        family.family_members.each do |family_member|
          family_member_person = family_member&.person
          family_member_attributes = {
            family_member_attributes: family_member.attributes
            person_attributes: family_member_person&.attributes
          }
          family_member_attributes.merge(
            conosumer_role: family_member_person.consumer_role.attributes
          ) if family_member_person.has_active_consumer_role?
          payload[:family_members] << family_member_attributes
        end
        payload
      end

      def build_event(payload)
        # event("events.sugar_crm.publish_family.#{@event_name}", attributes: payload)
        true
      end

      def publish(event)
        Success("Successfully published the payload for event: #{@event_name}") if event.publish
      end
    end
  end
end
