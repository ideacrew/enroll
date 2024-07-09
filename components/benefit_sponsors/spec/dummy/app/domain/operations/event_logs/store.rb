# frozen_string_literal: true

require "dry/monads"
require "dry/monads/do"

module Operations
  module EventLogs
    # Persist Audit Log Event
    class Store
      include Dry::Monads[:do, :result]
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
        headers.deep_symbolize_keys!

        options =
          headers.slice(
            :subject_gid,
            :correlation_id,
            :message_id,
            :host_id,
            :event_name
          )

        account = headers[:account]
        options[:event_time] = formated_time(headers[:event_time])
        options[:session_detail] = account[:session]
        options[:account_id] = account[:id]
        options[:session_detail][:login_session_id] = SecureRandom.uuid
        options[:monitored_event] = construct_monitored_event(payload, headers)
        options[:payload] = payload.to_json
        options[:event_category] = event_category_for(options[:event_name])

        Success(options)
      end

      def construct_monitored_event(_payload, headers)
        options = headers.slice(:event_category, :market_kind)

        account = headers[:account]
        user_account = account_with(account_id)
        options[:account_hbx_id] = user_account.person.hbx_id 
        options[:account_username] = user_account.username
        options[:login_session_id] = account[:session][:login_session_id]
        options[:event_category] = event_category_for(headers[:event_name])
        options.merge(
          {
            event_time: formated_time(headers[:event_time]),
            subject_hbx_id: subject_for(headers[:subject_gid])&.hbx_id
          }
        )
      end

      def account_with(account_id)
        User.find(account_id)
      end

      def event_category_for(event_name)
        event_name.split(".")[-2].to_sym
      end

      def subject_for(subject_gid)
        @subject ||= GlobalID::Locator.locate(subject_gid)
      rescue Mongoid::Errors::DocumentNotFound
        @subject = nil
      end

      def init_resource_handler(options)
        resource_handler.event_name = options[:event_name]

        if resource_handler.resource_class_reference
          Success(resource_handler)
        else
          Failure("Invalid event name: #{options[:event_name]}")
        end
      end

      def create(params)
        Operations::EventLogs::Create.new.call(params)
      end

      def store(values)
        return Failure("persistence model class not defined") unless persistence_model_class

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
