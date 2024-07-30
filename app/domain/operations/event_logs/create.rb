# frozen_string_literal: true

require "dry/monads"
require "dry/monads/do"

module Operations
  module EventLogs
    # Create Event Log entity
    class Create
      include Dry::Monads[:do, :result]

      attr_accessor :resource_class

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
        _resource_handler = yield init_resource_handler(params)
        values = yield validate(params)
        entity = yield create(values)

        Success(entity)
      end

      private

      delegate :domain_contract_class,
               :domain_entity_class,
               to: :resource_handler

      def init_resource_handler(options)
        resource_handler.event_name = options[:event_name]

        if resource_handler.resource_class_reference
          Success(resource_handler)
        else
          Failure("Invalid event name: #{options[:event_name]}")
        end
      end

      def validate(params)
        return Failure("domain contract not defined") unless domain_contract_class
        result = domain_contract_class.new.call(params)
        result.success? ? Success(result.to_h) : Failure(result.errors)
      rescue NameError => e
        Failure(e.message)
      end

      def create(values)
        return Failure("domain entity not defined") unless domain_entity_class

        Success(domain_entity_class.new(values))
      rescue NameError => e
        Failure(e.message)
      end

      def resource_handler
        return @resource_handler if @resource_handler

        @resource_handler = Class.new { include EventLog }.new
      end
    end
  end
end
