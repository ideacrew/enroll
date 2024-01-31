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

          include ::Operations::Transmittable::TransmittableUtils

          # @param [ Hash ] params Applicant Attributes
          # @return [ BenefitMarkets::Entities::Applicant ] applicant Applicant
          def call(person)
            values = yield build_transmittable_values(person)
            @job = yield create_job(values)
            transmission_params = yield construct_response_transmission_params(values)
            @transmission = yield create_request_transmission(transmission_params, @job)
            transaction_params = yield construct_response_transaction_params(values, person)
            @transaction = yield create_request_transaction(transaction_params, @job)
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

          def construct_response_transmission_params(values)
            values[:key] = :ssa_verification_request
            values[:event] = 'initial'
            values[:state_key] = :initial
            values[:job] = @job
            Success(values)
          end

          def construct_response_transaction_params(values, person)
            values[:key] = :ssa_verification_request
            values[:event] = 'initial'
            values[:state_key] = :initial
            values[:transmission] = @transmission
            values[:subject] = person
            Success(values)
          end

          def build_and_validate_payload_entity(person)
            result = Operations::Fdsh::BuildAndValidatePersonPayload.new.call(person, :ssa)
            if result.success?
              @transaction.json_payload = result.value!.to_h
              @transaction.save
              @transaction.json_payload ? Success(@transaction) : Failure("Unable to save transaction with payload")
            else
              add_errors("Unable to transform payload",
                         :build_and_validate_payload_entity,
                         { job: @job, transmission: @transmission, transaction: @transaction })
              status_result = update_status("Unable to transform payload", :failed,
                                            { job: @job, transmission: @transmission, transaction: @transaction })
              return status_result if status_result.failure?
              result
            end
          rescue StandardError
            add_errors("Unable to save transaction with payload", :generate_transmittable_payload,
                       { job: @job, transmission: @transmission, transaction: @transaction })
            status_result = update_status("Unable to save transaction with payload", :failed,
                                          { job: @job, transmission: @transmission, transaction: @transaction })
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
            update_status("successfully sent request to fdsh_gateway", :transmitted, { job: @job })
            update_status("successfully sent request to fdsh_gateway", :succeeded, { transmission: @transmission, transaction: @transaction })

            Success("Successfully published the payload to fdsh_gateway")
          end
        end
      end
    end
  end
end
