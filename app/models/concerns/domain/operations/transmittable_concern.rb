# frozen_string_literal: true

module Domain
  module Operations
    # This concern is designed for code reuse within domain operations(class that include Dry::Monads[:result, :do]).
    # It provides a set of generic methods or steps specifically tailored for Transmittable 2.0 functionality.
    # The methods within this concern are focused on the creation of Job, Transmission, Transaction, Error, and ProcessStatus objects, offering a modular and reusable solution for related operations within the domain.
    module TransmittableConcern
      extend ActiveSupport::Concern

      included do
        def add_errors(error_key, message, transmittable_objects)
          ::Operations::Transmittable::AddError.new.call(
            {
              key: error_key,
              message: message,
              transmittable_objects: transmittable_objects
            }
          )
        end

        def create_job(job_params)
          ::Operations::Transmittable::CreateJob.new.call(job_params)
        end

        def create_transaction(transaction_params, job)
          result = ::Operations::Transmittable::CreateTransaction.new.call(transaction_params)
          return result if result.success?

          add_errors(
            :create_request_transaction,
            "Failed to create transaction due to #{result.failure}",
            { job: job, transmission: transmission }
          )
          status_result = update_status(result.failure, :failed, { job: job, transmission: transmission })
          status_result.failure? ? status_result : result
        end

        def create_transmission(transmission_params, job)
          result = ::Operations::Transmittable::CreateTransmission.new.call(transmission_params)
          return result if result.success?

          add_errors(
            :create_request_transmission,
            "Failed to create transmission due to #{result.failure}",
            { job: job }
          )
          status_result = update_status(result.failure, :failed, { job: job })
          status_result.failure? ? status_result : result
        end

        def update_status(message, state, transmittable_objects)
          ::Operations::Transmittable::UpdateProcessStatus.new.call(
            {
              message: message,
              state: state,
              transmittable_objects: transmittable_objects
            }
          )
        end
      end
    end
  end
end
