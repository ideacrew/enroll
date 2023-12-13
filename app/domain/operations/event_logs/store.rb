# frozen_string_literal: true

require "dry/monads"
require "dry/monads/do"

module Operations
  module EventLogs
    # Persist Audit Log Event
    class Store
      send(:include, Dry::Monads[:result, :do])

      # @param [Hash] opts Options to persist event log event
      # @option opts [<GlobalID>] :account_gid required
      # @option opts [<String>] :subject_gid required
      # @option opts [<String>] :correlation_id required
      # @option opts [<String>] :host_id required
      # @option opts [<String>] :trigger required
      # @option opts [<String>] :event_category required
      # @option opts [<DateTime>] :event_time required
      # @option opts [<Hash>] :session_detail required
      # @return [Dry::Monad] result
      def call(payload: {}, headers: {})
        options = yield construct_params(payload, headers)
        resource_class = yield resource_class_for(options)
        resource_class = yield validate_domain_entities(resource_class)
        entity = yield create(options, resource_class)
        event_log = yield store(entity, resource_class)

        Success(event_log)
      end

      private

      def construct_params(payload, headers)
        payload.symbolize_keys!
        headers.symbolize_keys!

        Success(
          {
            account_id: payload[:account_id],
            subject_gid: payload[:subject_gid],
            correlation_id: headers[:correlation_id],
            message_id: payload[:message_id],
            host_id: headers[:host_id],
            trigger: payload[:trigger],
            event_category: payload[:event_category],
            event_time: DateTime.strptime(payload[:event_time], "%m/%d/%Y %H:%M"),
            session_detail: payload[:session_detail]
          }
        )
      end

      def validate_domain_entities(resource_class)
        entities = [
          "AcaEntities::EventLogs::#{resource_class}EventLogContract",
          "AcaEntities::EventLogs::#{resource_class}EventLog",
          "EventLogs::#{resource_class}EventLog"
        ]

        errors =
          entities
          .map do |entity_class|
            "#{entity_class} not defined" unless domain_entity_defined?(entity_class)
          end
          .compact

        errors.empty? ? Success(resource_class) : Failure(errors)
      end

      def create(params, resource_class)
        result = Operations::EventLogs::Create.new.call(
          params.merge(resource_class: resource_class)
        )

        result.success? ? result : Failure(result.failure.errors)
      end

      def store(values, resource_class)
        log_event =
          "EventLogs::#{resource_class}EventLog".constantize.new(values.to_h)

        log_event.save ? Success(log_event) : Failure(log_event)
      end

      def resource_class_for(params)
        resource = GlobalID::Locator.locate params[:subject_gid]
        Success(resource.class)
      end

      def domain_entity_defined?(class_name)
        Success(Object.const_get(class_name))
      rescue NameError
        Failure(false)
      end
    end
  end
end
