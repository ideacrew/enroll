# frozen_string_literal: true

require "dry/monads"
require "dry/monads/do"

module Operations
  module EventLogs
    # Publish trackable event
    class TrackableEvent
      include Dry::Monads[:do, :result]
      include EventSource::Command
      include EventSource::Logging

      attr_accessor :event_name

      # @param [Hash] opts Options to build trackable event
      # @option opts [<Object>] :subject required
      # @option opts [<Object>] :resource required
      # @option opts [<String>] :event_name required
      # @option opts [<Hash>] :payload optional
      # @return [Dry::Monad] result
      def call(params)
        values = yield validate(params)
        headers, payload = yield build_options(values)
        event = yield create(headers, payload)
        _result = yield publish(event)

        Success(event)
      end

      private

      def validate(params)
        errors = []
        errors << "subject is required" unless params[:subject]
        errors << "resource is required" unless params[:subject]
        errors << "event name is required" unless params[:event_name]

        errors.empty? ? Success(params) : Failure(errors)
      end

      def build_options(params)
        @event_name = params[:event_name]

        headers = {}
        headers[:subject_gid] = params[:subject].to_global_id.to_s
        headers[:resource_gid] = params[:resource].to_global_id.to_s
        payload = params[:payload] || {}

        Success([headers, payload])
      end

      def create(headers, payload)
        event(
          event_name,
          attributes: payload,
          headers:
            headers.merge(event_time: DateTime.now.utc, build_message: true)
        )
      end

      def publish(event)
        unless Rails.env.test?
          logger.info("-" * 100)
          logger.info(
            "Enroll Trackable Event Publish to external systems,
              event_name: #{event_name} payload: #{event.message.payload} headers: #{event.message.headers}"
          )
          logger.info("-" * 100)
        end

        Success(event.publish)
      end
    end
  end
end
