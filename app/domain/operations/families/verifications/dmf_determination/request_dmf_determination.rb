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
            family = yield find_family(valid_payload)

            @job = yield find_job(valid_payload[:job_id])
            values = yield construct_request_values(family.hbx_assigned_id)

            @transmission = yield build_and_create_request_transmission(values)
            @transaction = yield build_and_create_request_transaction(values, family)

            payload = yield build_cv3_family_payload(family)
            event = yield build_event(payload)
            result = yield publish(event)

            Success(result)
          end

          private

          def validate(payload)
            return handle_dmf_error('ALIVE_STATUS is not enabled for this env') unless EnrollRegistry.feature_enabled?(:alive_status)
            return handle_dmf_error('Missing param :family_hbx_id') unless payload[:family_hbx_id].present?
            return handle_dmf_error('Missing param :job_id') unless payload[:job_id].present?

            Success(payload)
          end

          def find_family(params[:family_hbx_id])
            family = Family.find_by(hbx_assigned_id: params[:family_hbx_id])
            Success(family)
          rescue Mongoid::Errors::DocumentNotFound
            handle_dmf_error("Family with hbx_id #{params[:family_hbx_id]} not found")
          end

          def find_job(job_id)
            job = ::Transmittable::Job.where(job_id: job_id).last
            return handle_dmf_error("Could not find Transmittable::Job with job_id #{job_id}") unless job.present?

            Success(job)
          end

          def construct_request_values(family_hbx_id)
            Success({
                      key: @job&.key,
                      title: @job&.title,
                      description: @job&.description,
                      correlation_id: family_hbx_id.to_s,
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

              payload = { family_hash: @transaction.json_payload, job_id: @job.job_id }
              @transaction.json_payload ? Success(payload) : Failure("Unable to save transaction with payload")
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
            event('events.families.verifications.dmf_determination.requested', attributes: payload)
          end

          def publish(event)
            hbx_id = @transaction.json_payload[:hbx_id]
            event.publish

            message = "successfully sent dmf determination request for family with hbx_id #{hbx_id} to fdsh_gateway"
            update_status(message, :transmitted, { job: @job })
            update_status(message, :succeeded, { transmission: @transmission, transaction: @transaction })

            Success(message)
          end

          # logs error and returns Failure
          # used to log all failures that occur prior to finding job
          def handle_dmf_error(error)
            dmf_logger.error(error)
            Failure(error)
          end

          def dmf_logger
            @dmf_logger ||= Logger.new("#{Rails.root}/log/dmf_logger_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
          end
        end
      end
    end
  end
end
