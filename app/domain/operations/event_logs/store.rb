# frozen_string_literal: true

require "dry/monads"
require "dry/monads/do"

module Operations
  module EventLogs
    # Persist Audit Log Event
    class Store
      include Dry::Monads[:result, :do]

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
        _resource_handler = yield init_resource_handler(options)
        entity = yield create(options)
        event_log = yield store(entity)

        Success(event_log)
      end

      private

      delegate :persistence_model_class, to: :resource_handler

      def construct_params(payload, headers)
        payload.symbolize_keys!
        headers.symbolize_keys!

        Success(
          account_id: payload[:account_id],
          subject_gid: payload[:subject_gid],
          correlation_id: headers[:correlation_id],
          message_id: payload[:message_id],
          host_id: headers[:host_id],
          trigger: payload[:trigger],
          event_category: payload[:event_category],
          event_time: DateTime.strptime(payload[:event_time], "%m/%d/%Y %H:%M"),
          session_detail: payload[:session_detail]
        )
      end

      def init_resource_handler(options)
        resource_handler.subject_gid = options[:subject_gid]

        if resource_handler.associated_resource
          Success(resource_handler)
        else
          Failure(
            "Unable to find resource for subject_gid: #{options[:subject_gid]}"
          )
        end
      end

      def create(params)
        result = Operations::EventLogs::Create.new.call(params)

        result.success? ? result : Failure(result.failure.errors)
      end

      def store(values)
        return Failure("persistence model class not defined") unless persistence_model_class

        log_event = persistence_model_class.new(values.to_h)
        log_event.save ? Success(log_event) : Failure(log_event)
      end

      def resource_handler
        return @resource_handler if @resource_handler

        @resource_handler = Class.new do
          include Mongoid::Document
          include EventLog
        end.new
      end
    end
  end
end
