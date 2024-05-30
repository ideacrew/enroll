# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    module Verifications
      module DmfDetermination
        # operation to manually trigger dmf events
        class RequestDmfDetermination
          include Dry::Monads[:result, :do]
          include EventSource::Command
          include EventSource::Logging
          include ::Operations::Transmittable::TransmittableUtils

          # @return [ Success ] Job successfully completed
          def call(payload)
            valid_payload = yield validate(payload)
            family = yield find_family(valid_payload[:family_hbx_id])

            @job = yield find_job(valid_payload[:job_id])
            values = yield construct_request_values(family.hbx_assigned_id)

            @transmission = yield build_and_create_request_transmission(values)
            @transaction = yield build_and_create_request_transaction(values, family)

            payload = build_cv3_family_payload(family)
            yield publish(payload)

            Success("Successfully Requested DMF Determination for Family with hbx_id #{family.hbx_assigned_id}")
          end

          private

          def validate(payload)
            return log_error_and_return_failure('ALIVE_STATUS is not enabled for this env') unless EnrollRegistry.feature_enabled?(:alive_status)
            return log_error_and_return_failure('Missing param :family_hbx_id') unless payload[:family_hbx_id].present?
            return log_error_and_return_failure('Missing param :job_id') unless payload[:job_id].present?

            Success(payload)
          end

          def find_family(family_hbx_id)
            families = Family.where(hbx_assigned_id: family_hbx_id)

            case families.size
            when 1
              Success(families.first)
            when 0
              log_error_and_return_failure("Family with hbx_id #{family_hbx_id} not found")
            else
              log_error_and_return_failure("Multiple Families with hbx_id #{family_hbx_id} found: unable to proceed")
            end
          end

          def find_job(job_id)
            job = Transmittable::Job.where(job_id: job_id).last
            return log_error_and_return_failure("Could not find Transmittable::Job with job_id #{job_id}") unless job.present?

            Success(job)
          end

          def construct_request_values(family_hbx_id)
            Success({
                      key: @job&.key,
                      title: @job&.title,
                      description: @job&.description,
                      correlation_id: family_hbx_id,
                      started_at: @job&.started_at,
                      publish_on: @job&.publish_on
                    })
          end

          def build_and_create_request_transmission(values)
            values[:key] = :dmf_determination_request
            values[:event] = 'initial'
            values[:state_key] = :initial
            values[:job] = @job

            create_request_transmission(values, @job)
          end

          def build_and_create_request_transaction(values, family)
            values[:key] = :dmf_determination_request
            values[:event] = 'initial'
            values[:state_key] = :initial
            values[:transmission] = @transmission
            values[:subject] = family

            create_request_transaction(values, @job)
          end

          def build_cv3_family_payload(family)
            cv3_family = Operations::Transformers::FamilyTo::Cv3Family.new.call(family)

            if cv3_family.success?
              @transaction.json_payload = cv3_family.value!.to_h
              @transaction.save
              @transaction.json_payload ? Success(@transaction.json_payload) : Failure("Unable to save transaction with payload")
            else
              message = "Unable to transform family into cv3_family"
              add_errors(message, :build_and_validate_cv3_family, { job: @job, transmission: @transmission, transaction: @transaction })
              status_result = update_status(message, :failed,
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

          def build_event(payload)
            binding.irb
            event('events.families.verifications.dmf_determination.requested', attributes: payload, headers: { job_id: @job.id })
          end

          def publish(payload)
            event = build_event(payload)
            event.success.publish

            update_status("successfully sent dmf determination request to fdsh_gateway", :transmitted, { job: @job })
            update_status("successfully sent dmf determination request to fdsh_gateway", :succeeded, { transmission: @transmission, transaction: @transaction })

            Success("Successfully published request dmf determination payload")
          end

          # Used to log all failures that occur prior to generating job/transmission/transaction
          def log_error_and_return_failure(error)
            requested_dmf_logger.error(error)
            Failure(error)
          end

          def requested_dmf_logger
            @requested_dmf_logger ||= Logger.new("#{Rails.root}/log/requested_dmf_logger_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
          end
        end
      end
    end
  end
end
