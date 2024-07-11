# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Events
    # Operation is to build and publish an event_source event
    class BuildAndPublish
      include Dry::Monads[:do, :result]
      include EventSource::Command

      # @param [Hash] opts The options build and publish an event_source event
      # @option opts [String] :event_name
      # @option opts [Hash] :attributes
      # @option opts [Hash] :headers
      # @example
      #   { event_name: 'events.families.found_by', attributes: { errors: [], family: {} }, headers: { correlation_id: '' } }
      # @return [Dry::Monads::Result]
      def call(params)
        values = yield validate(params)
        event  = yield build_event(values)
        result = yield publish(event)

        Success(result)
      end

      private

      def build_event(values)
        event(values[:event_name], attributes: values[:attributes], headers: values[:headers] || {})
      end

      def publish(event)
        event.publish

        Success("Successfully published event: #{event.name}")
      end

      def validate(params)
        errors = []
        errors << 'event_name is required and must be a string' unless params[:event_name].is_a?(String)
        errors << 'attributes is required and must be a hash' unless params[:attributes].is_a?(Hash)
        errors << 'headers is required' unless params.key?(:headers)

        errors.present? ? Failure(errors) : Success(params)
      end
    end
  end
end
