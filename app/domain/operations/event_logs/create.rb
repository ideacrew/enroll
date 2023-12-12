# frozen_string_literal: true

require "dry/monads"
require "dry/monads/do"

module Operations
  module EventLogs
    # Create Event Log entity
    class Create
      send(:include, Dry::Monads[:result, :do])

      attr_reader :resource_class

      # @param [Hash] opts Options to build audit log event
      # @option opts [<GlobalID>] :subject_gid required
      # @option opts [<String>]   :correlation_id required
      # @option opts [<Symbol>]   :event_category required
      # @option opts [<String>]   :session_id optional
      # @option opts [<String>]   :account_id optional
      # @option opts [<String>]   :host_id required
      # @option opts [<String>]   :trigger required
      # @option opts [<String>]   :response required
      # @option opts [<Symbol>]   :log_level optional
      # @option opts [<Symbol>]   :severity optional
      # @option opts [<DateTime>] :event_time required
      # @option opts [<Array>]    :tags optional
      # @return [Dry::Monad] result
      def call(params)
        values = yield validate(params)
        entity = yield create(values)

        Success(entity)
      end

      private

      def validate(params)
        resource_class = params.delete(:resource_class)
        return Failure("resource class name missing") unless resource_class

        result =
          "AcaEntities::EventLogs::#{resource_class}EventLogContract"
            .constantize
            .new
            .call(params)
        result.success? ? Success(result) : Failure(result)
      end

      def create(values)
        Success(
          "AcaEntities::EventLogs::#{resource_class}EventLog".constantize.new(
            values.to_h
          )
        )
      end
    end
  end
end
