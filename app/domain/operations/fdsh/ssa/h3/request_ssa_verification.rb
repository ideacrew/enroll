# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Fdsh
    module Ssa
      module H3
        # vlp initial request
        class RequestSsaVerification
          # primary request from fdsh gateway

          include Dry::Monads[:result, :do, :try]
          include EventSource::Command

          # @param [ Hash ] params Applicant Attributes
          # @return [ BenefitMarkets::Entities::Applicant ] applicant Applicant
          def call(person)
            values = yield build_transmittable_values(person)
            _job = yield create_job(values)
            _transmission = yield create_transmission(values)
            _transaction = yield create_transaction(values, person)
            _payload_entity = yield build_and_validate_payload_entity(person)
            event  = yield build_event
            result = yield publish(event)

            Success(result)
          end

          private

          def build_transmittable_values(person)
            return Failure("Person is required to request ssa verification") if person&.hbx_id.blank?

            Success({ key: :ssa_verification,
                      title: 'SSA Verification',
                      description: 'Request for SSA verification to fdsh gateway',
                      correlation_id: person.hbx_id,
                      started_at: DateTime.now,
                      publish_on: DateTime.now})
          end

          def create_job(values)
            result = Operations::Transmittable::FindOrCreateJob.new.call(values)

            if result.success?
              @job = result.value!
              Success(@job)
            else
              result
            end
          end

          def create_transmission(values)
            values[:key] = :ssa_verification_request
            result = Operations::Transmittable::CreateTransmission.new.call(values.merge({ job: @job, event: 'initial', state_key: :initial }))

            if result.success?
              @transmission = result.value!
            else
              add_errors({ job: @job }, "Failed to create transmission due to #{result.failure}", :create_request_transmission)
              status_result = update_status({ job: @job }, :failed, result.failure)
              return status_result if status_result.failure?
            end
            result
          end

          def create_transaction(values, person)
            result = Operations::Transmittable::CreateTransaction.new.call(values.merge({ transmission: @transmission,
                                                                                          subject: person,
                                                                                          event: 'initial',
                                                                                          state_key: :initial }))
            if result.success?
              @transaction = result.value!
            else
              add_errors({ job: @job, transmission: @transmission }, "Failed to create transaction due to #{result.failure}", :create_transaction)
              status_result = update_status({ job: @job, transmission: @transmission }, :failed, result.failure)
              return status_result if status_result.failure?
            end
            result
          end

          def build_and_validate_payload_entity(person)
            result = Operations::Fdsh::BuildAndValidatePersonPayload.new.call(person, :ssa)
            if result.success?
              @transaction.json_payload = result.value!.to_h
              @transaction.save
              @transaction.json_payload ? Success(@transaction) : Failure("Unable to save transaction with payload")
            else
              add_errors({ job: @job, transmission: @transmission, transaction: @transaction },
                         "Unable to transform payload",
                         :build_and_validate_payload_entity)
              status_result = update_status({ job: @job, transmission: @transmission, transaction: @transaction }, :failed, "Unable to transform payload")
              return status_result if status_result.failure?
              result
            end
          rescue StandardError
            add_errors({ job: @job, transmission: @transmission, transaction: @transaction },
                       "Unable to save transaction with payload",
                       :generate_transmittable_payload)
            status_result = update_status({ job: @job, transmission: @transmission, transaction: @transaction }, :failed,
                                          "Unable to save transaction with payload")
            return status_result if status_result.failure?
            result
          end

          def build_event
            payload = @transaction.json_payload
            event('events.fdsh.ssa.h3.ssa_verification_requested', attributes: payload, headers: { job_id: @job.job_id,
                                                                                                   correlation_id: @transaction.transaction_id,
                                                                                                   payload_type: EnrollRegistry[:ssa_h3].setting(:payload_type).item })
          end

          def publish(event)
            event.publish
            update_status({ job: @job }, :transmitted, "successfully sent request to fdsh_gateway")
            update_status({ transmission: @transmission, transaction: @transaction }, :succeeded, "successfully sent request to fdsh_gateway")

            Success("Successfully published the payload to fdsh_gateway")
          end

          def add_errors(transmittable_objects, message, error_key)
            Operations::Transmittable::AddError.new.call({ transmittable_objects: transmittable_objects, key: error_key, message: message })
          end

          def update_status(transmittable_objects, state, message)
            Operations::Transmittable::UpdateProcessStatus.new.call({ transmittable_objects: transmittable_objects, state: state, message: message })
          end
        end
      end
    end
  end
end
