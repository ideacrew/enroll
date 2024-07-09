# frozen_string_literal: true

module Operations
  module Transmittable
    # Update the process status of a transmittable object
    class UpdateProcessStatus
      include Dry::Monads[:do, :result]

      def call(params)
        values = yield validate_params(params)
        process_state = yield create_process_state(values)
        result = yield update_status(values, process_state)
        Success(result)
      end

      private

      def validate_params(params)
        return Failure('Transmittable objects are not present to update the process status') unless params[:transmittable_objects].is_a?(Hash)
        return Failure('State must be present to update the process status') unless params[:state].is_a?(Symbol)
        return Failure('Message must be present to update the process status') unless params[:message].is_a?(String)
        Success(params)
      end

      def update_status(values, process_state)
        values[:transmittable_objects].each do |_key, transmittable_object|
          transmittable_object.process_status.latest_state = values[:state]
          last_process_state = transmittable_object&.process_status&.process_states&.last
          last_process_state.ended_at = DateTime.now if last_process_state
          transmittable_object.process_status.process_states.create(process_state.to_h)
          if [:failed, :completed, :succeeded].include?(values[:state])
            last_process_state = transmittable_object&.process_status&.process_states&.last
            transmittable_object.ended_at = DateTime.now
            last_process_state.ended_at = DateTime.now
          end
          transmittable_object.process_status.save
          transmittable_object.save
        end
        Success("Process status updated successfully")
      rescue StandardError => e
        Operations::Transmittable::AddError.new.call({ transmittable_objects: values[:transmittable_objects], key: :update_process_status,
                                                       message: "Error updating process status: #{e.message}" })
        Failure("Error updating process status: #{e.message}")
      end

      def create_process_state(values)
        validation_result = AcaEntities::Protocols::Transmittable::Operations::ProcessStates::Create.new.call({ event: values[:state].to_s,
                                                                                                                message: values[:message],
                                                                                                                started_at: DateTime.now,
                                                                                                                state_key: values[:state] })

        validation_result.success? ? Success(validation_result.value!) : validation_result
      end
    end
  end
end