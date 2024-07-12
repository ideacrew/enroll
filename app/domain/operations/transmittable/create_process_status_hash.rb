# frozen_string_literal: true

module Operations
  module Transmittable
    # create process status takes event(:string), state_key(:symbol) and started_at(DateTime) as inputs
    class CreateProcessStatusHash
      include Dry::Monads[:do, :result]

      def call(params)
        values = yield validate_params(params)
        status_hash = yield create_process_status_hash(values)
        Success(status_hash)
      end

      private

      def validate_params(params)
        return Failure('Process state event should be a string') unless params[:event].is_a?(String)
        return Failure('Process state message should be a string') unless params[:message].is_a?(String)
        return Failure('Process state key should be a symbol') unless params[:state_key].is_a?(Symbol)
        return Failure('Process state should have a started_at Datetime') unless params[:started_at].is_a?(DateTime)

        Success(params)
      end

      def initial_process_state(values)
        {
          event: values[:event],
          message: values[:message],
          started_at: values[:started_at],
          ended_at: values[:ended_at],
          state_key: values[:state_key]
        }
      end

      def create_process_status_hash(values)
        Success({
                  initial_state_key: values[:state_key],
                  latest_state: values[:state_key],
                  elapsed_time: values[:elapsed_time],
                  process_states: [initial_process_state(values)]
                })
      end
    end
  end
end
