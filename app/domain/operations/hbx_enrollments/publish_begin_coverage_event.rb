# frozen_string_literal: true

module Operations
  module HbxEnrollments
    # Publish event to begin IVL enrollment coverage
    class PublishBeginCoverageEvent
      include EventSource::Command
      include Dry::Monads[:result, :do]

      # @param [Hash] params
      # @option params [Hash] :enrollment
      # @return [Dry::Monads::Result]
      def call(params)
        values            = yield validate(params)
        event             = yield build_event(values[:enrollment])
        result            = yield publish_event(event)
        Success(result)
      end

      private

      def validate(params)
        return Failure("Invalid input params: #{params}.") unless params.is_a?(Hash) && params[:enrollment].is_a?(::HbxEnrollment)

        Success(params)
      end

      def build_event(enrollment)
        event = event("events.individual.enrollments.begin_coverages.begin", attributes: { enrollment_hbx_id: enrollment.hbx_id })
        if event.success?
          event
        else
          Failure("Failure building event: #{event.failure}")
        end
      end

      def publish_event(event)
        result = event.publish
        if result
          Success("Successfully published begin coverage event.")
        else
          Failure("Failure publishing event.")
        end
      end
    end
  end
end
