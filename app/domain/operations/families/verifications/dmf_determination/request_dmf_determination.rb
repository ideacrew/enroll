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
            @family = yield find_family(valid_payload[:family_hbx_id])

            @job = yield find_job(valid_payload[:job_id])
            values = yield construct_base_request_values

            @transmission = yield build_and_create_request_transmission(values)
            @transaction = yield build_and_create_request_transaction(values)
            yield record_verification_history
            payload = yield build_cv3_family_payload
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

          def find_family(family_hbx_id)
            family = Family.find_by(hbx_assigned_id: family_hbx_id.to_i)
            Success(family)
          rescue Mongoid::Errors::DocumentNotFound
            handle_dmf_error("Could not find Family with hbx_id #{family_hbx_id}")
          end

          def find_job(job_id)
            job = ::Transmittable::Job.find_by(job_id: job_id.to_s)
            Success(job)
          rescue Mongoid::Errors::DocumentNotFound
            handle_dmf_error("Could not find Transmittable::Job with job_id #{job_id}")
          end

          def construct_base_request_values
            hbx_id = @family.hbx_assigned_id.to_s
            values = {
              key: :dmf_determination_request,
              # title is 'DMF Determination', specify 'Request' in title
              title: "#{@job.title} Request",
              # specify in description which family in bulk call
              description: "#{@job.description}: individual call for family with hbx_id #{hbx_id}",
              correlation_id: hbx_id,
              transmission_id: hbx_id,
              transaction_id: hbx_id,
              started_at: DateTime.now,
              publish_on: DateTime.now,
              event: 'initial',
              state_key: :initial
            }

            Success(values)
          end

          def build_and_create_request_transmission(values)
            values[:job] = @job

            create_request_transmission(values, @job)
          end

          def build_and_create_request_transaction(values)
            values[:transmission] = @transmission
            values[:subject] = @family

            create_request_transaction(values, @job)
          end

          def build_cv3_family_payload
            transmission_params = { job: @job, transmission: @transmission, transaction: @transaction }
            BuildCv3FamilyPayloadForDmf.new.call(@family, transmission_params)
          end

          def build_event(payload)
            event('events.families.verifications.dmf_determination.requested', attributes: payload)
          end

          def record_verification_history
            @family.family_members.each do |member|
              message = "DMF Determination request for Family with hbx_id #{@family.hbx_assigned_id} is submitted"
              person = member.person
              alive_status_type = person.verification_types.alive_status_type.first
              alive_status_type.add_type_history_element(action: "DMF_Request_Submitted", modifier: "System", update_reason: message)
            end

            Success(true)
          end

          def publish(event)
            event.publish
            message = "DMF Determination request for Family with hbx_id #{@family.hbx_assigned_id} is submitted"
            update_status(message, :succeeded, { transmission: @transmission, transaction: @transaction })

            Success(message)
          end

          # logs error and returns Failure
          # used to log all failures that occur prior to finding transmittable job
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
