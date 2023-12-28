# frozen_string_literal: true

require "dry/monads"
require "dry/monads/do"

module Operations
  module EventLogs
    # Persist Audit Log Event
    class Store
      include Dry::Monads[:result, :do]
      include Config::AcaModelConcern

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
        yield is_event_log_feature_enabled?
        options = yield construct_params(payload, headers)
        _resource_handler = yield init_resource_handler(options)
        entity = yield create(options)
        event_log = yield store(entity)

        Success(event_log)
      end

      private

      delegate :persistence_model_class, to: :resource_handler

      def is_event_log_feature_enabled?
        return Success(true) if event_logging_enabled?

        Failure("Event logging is not enabled")
      end

      def construct_params(payload, headers)
        payload.symbolize_keys!
        headers.symbolize_keys!

        options =
          headers.slice(
            :account_id,
            :subject_gid,
            :correlation_id,
            :message_id,
            :host_id,
            :trigger,
            :event_category
          )

        options[:event_time] = formated_time(headers[:event_time])
        options[:session_detail] = headers[:session]
        options[:session_detail][:login_session_id] = SecureRandom.uuid
        options[:monitored_event] = construct_monitored_event(payload, headers)

        Success(options)
      end

      def construct_monitored_event(payload, headers)
        options =
          headers.slice(
            :account_id,
            :event_category,
            :market_kind
          )

        options.merge(
          {
            event_time: formated_time(headers[:event_time]),
            login_session_id: headers[:session][:login_session_id],
            subject_hbx_id: subject_for(headers[:subject_gid])&.hbx_id
          }
        )
      end

      def subject_for(subject_gid)
        @subject ||= GlobalID::Locator.locate(subject_gid)
      rescue Mongoid::Errors::DocumentNotFound
        @subject = nil
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
        Operations::EventLogs::Create.new.call(params)
      end

      def store(values)
        unless persistence_model_class
          return Failure("persistence model class not defined")
        end

        log_event = persistence_model_class.new(values.to_h)
        log_event.save ? Success(log_event) : Failure(log_event)
      end

      def resource_handler
        return @resource_handler if @resource_handler

        @resource_handler = Class.new { include EventLog }.new
      end

      def formated_time(time)
        time.to_datetime
      end
    end
  end
end
