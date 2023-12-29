# frozen_string_literal: true

require "dry/monads"
require "dry/monads/do"

module Operations
  module EventLogs
    # Publish trackable event
    class TrackableEvent
      send(:include, Dry::Monads[:result, :do])
      include EventSource::Command
      include EventSource::Logging

      attr_accessor :event_name

      # @param [Hash] opts Options to build trackable event
      # @option opts [<Object>] :subject required
      # @option opts [<Object>] :resource required
      # @option opts [<String>] :market_kind required
      # @option opts [<String>] :event_name required
      # @option opts [<Hash>] :payload optional
      # @return [Dry::Monad] result
      def call(params)
        values = yield validate(options)
        headers, payload = yield build_options(values)
        event = yield create(headers, payload)
        result = yield publish(event)

        Success(event)
      end

      private

      def validate(params)
        errors = []
        errors << "subject is required" unless params[:subject]
        errors << "resource is required" unless params[:subject]
        errors << "market kind is required" unless params[:market_kind]
        errors << "event name is required" unless params[:event_name]

        errors.empty? ? Success(params) : Failure(errors)
      end

      def build_options(params)
        @event_name = params[:event_name]

        headers[:subject_gid] = params[:subject].to_global_id.to_s
        headers[:resource_gid] = params[:resource].to_global_id.to_s
        headers[:market_kind] = params[:market_kind]
        payload = params[:payload] || {}

        Success([headers, payload])
      end

      def create(headers, payload)
        event(
          event_name,
          attributes: payload,
          headers:
            options.merge(
              event_category: category,
              event_outcome: action.titleize,
              trigger: action,
              event_time: DateTime.now.utc,
              build_message: true
            )
        )
      end

      def publish(event)
        unless Rails.env.test?
          logger.info("-" * 100)
          logger.info(
            "Enroll Trackable Event Publish to external systems,
              event_name: #{event_name}, message: #{event.message.to_h}"
          )
          logger.info("-" * 100)
        end

        Success(event.publish)
      end

      def category
        event_name.split(".")[-2]
      end

      def action
        event_name.split(".").last
      end
    end
  end
end
