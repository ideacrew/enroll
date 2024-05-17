# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module HbxEnrollments
    # Publish event on enrollment change
    class PublishChangeEvent
      include Dry::Monads[:do, :result]
      include EventSource::Command

      def call(event_name:, enrollment:)
        _values             = yield validate(event_name, enrollment)
        payload             = yield build_payload(enrollment)
        validated_payload   = yield validate_payload(payload)
        entity              = yield family_entity(validated_payload)
        event               = yield build_event(event_name, entity)
        result              = yield publish(event)

        Success(result)
      end

      private

      def validate(event_name, enrollment)
        return Failure("Invalid Enrollment object #{enrollment}") unless enrollment.is_a?(HbxEnrollment)
        return Failure("Invalid event_name #{event_name}") unless ['initial_purchase', 'auto_renew', 'terminated'].include?(event_name)

        Success(enrollment)
      end

      def build_payload(enrollment)
        result = Operations::Transformers::FamilyTo::Cv3Family.new.call(enrollment.family)
        return result unless result.success?

        Success(result.value!)
      end

      def validate_payload(payload)
        result = ::AcaEntities::Contracts::Families::FamilyContract.new.call(payload)

        return Failure("invalid family payload due to #{result.errors&.to_h}") unless result.success?
        Success(result.to_h)
      end

      def family_entity(payload)
        Success(::AcaEntities::Families::Family.new(payload))
      end

      def build_event(event_name, payload)
        headers = {enrollment_event: event_name}
        event("events.individual.enrollments.#{event_name}", attributes: payload.to_h, headers: headers)
      end

      def publish(event)
        event.publish

        Success("Successfully published")
      end

    end
  end
end