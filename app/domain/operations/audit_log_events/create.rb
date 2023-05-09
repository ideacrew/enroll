# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module AuditLogEvents
    # Persist Audit Log Event
    class Create
      send(:include, Dry::Monads[:result, :do])

      # @param [Hash] opts Options to persist audit log event
      # @option opts [<GlobalID>] :subject_gid required
      # @option opts [<String>] :correlation_id required
      # @option opts [<String>] :event_category required
      # @option opts [<String>] :trigger required
      # @option opts [<String>] :response required
      # @option opts [<DateTime>] :event_time required
      # @return [Dry::Monad] result
      def call(params)
        event_params = yield construct_params(params)
        values = yield build(event_params)
        audit_event = yield create(values)

        Success(audit_event)
      end

      private

      def construct_params(params)
        Success({
                  subject_gid: params[:subject_gid],
                  correlation_id: params[:correlation_id],
                  event_category: params[:event_category],
                  trigger: params[:trigger],
                  response: params[:response],
                  event_time: params[:event_time]
                })
      end

      def build(params)
        result = Operations::AuditLogs::Build.new.call(params)
        result.success? ? Success(result.to_h) : Failure(result.failure.errors)
      end

      def create(values)
        log_event = AuditLogEvent.new(values)

        if log_event.save
          Success(log_event)
        else
          Failure(log_event)
        end
      end
    end
  end
end
