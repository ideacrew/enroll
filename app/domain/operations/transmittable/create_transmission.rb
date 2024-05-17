# frozen_string_literal: true

module Operations
  module Transmittable
    # create Transmission that takes params of key (required), job (required), started_at(required)
    class CreateTransmission
      include Dry::Monads[:do, :result]

      def call(params)
        values = yield validate_params(params)
        process_status = yield create_process_status(values[:event], values[:state_key])
        transmission_hash = yield build_transmission_hash(values, process_status)
        transmission_entity = yield transmission_entity(transmission_hash)
        transmission = yield create_transmission(params[:job], transmission_entity)
        Success(transmission)
      end

      private

      def validate_params(params)
        return Failure('Transmission cannot be created without key symbol') unless params[:key].is_a?(Symbol)
        return Failure('Transmission cannot be created without started_at datetime') unless params[:started_at].is_a?(DateTime)
        return Failure('Transmission cannot be created without a job') unless params[:job].is_a?(::Transmittable::Job)
        return Failure('Transmission cannot be created without event string') unless params[:event].is_a?(String)
        return Failure('Transmission cannot be created without state_key symbol') unless params[:state_key].is_a?(Symbol)
        return Failure('Transmission cannot be created without correlation_id string') unless params[:correlation_id].is_a?(String)

        Success(params)
      end

      def build_transmission_hash(values, process_status)
        Success({
                  key: values[:key],
                  title: values[:title],
                  description: values[:description],
                  started_at: values[:started_at],
                  ended_at: values[:ended_at],
                  process_status: process_status,
                  transmission_id: values[:correlation_id],
                  transmittable_errors: []
                })
      end

      def create_process_status(event, state_key)
        result = Operations::Transmittable::CreateProcessStatusHash.new.call({ event: event, state_key: state_key, started_at: DateTime.now,
                                                                               message: 'created transmission' })
        result.success? ? Success(result.value!) : result
      end

      def transmission_entity(transmission_hash)
        validation_result = AcaEntities::Protocols::Transmittable::Operations::Transmissions::Create.new.call(transmission_hash)

        validation_result.success? ? Success(validation_result.value!) : validation_result
      end

      def create_transmission(job, tranmission_entity)
        transmission = job.transmissions.new(tranmission_entity.to_h)

        transmission.save ? Success(transmission) : Failure("Failed to save transmission")
      end
    end
  end
end
