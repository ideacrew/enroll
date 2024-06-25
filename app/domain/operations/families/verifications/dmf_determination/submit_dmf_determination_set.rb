# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    module Verifications
      module DmfDetermination
        # operation to manually trigger dmf events
        class SubmitDmfDeterminationSet
          include Dry::Monads[:result, :do]
          include EventSource::Command
          include EventSource::Logging
          include ::Operations::Transmittable::TransmittableUtils

          # @return [ Success ] Job successfully completed
          def call
            families = yield query_families_with_active_members
            job = yield create_job(dmf_job_params)
            result = yield submit_for_dmf_determination(families, job)

            Success(result)
          end

          private

          def query_families_with_active_members
            return Failure('ALIVE_STATUS is not enabled for this env') unless EnrollRegistry.feature_enabled?(:alive_status)

            families = Family.enrolled_members_with_ssn
            Success(families)
          end

          def dmf_job_params
            {
              key: :dmf_determination,
              title: 'DMF Determination',
              description: 'Bulk Call to determine dmf for eligibile families',
              started_at: DateTime.now,
              publish_on: DateTime.now
            }
          end

          def submit_for_dmf_determination(families, job)
            count = 0

            families.each do |family|
              if family.hbx_assigned_id.present?
                publish({ family_hbx_id: family.hbx_assigned_id, job_id: job.job_id })

                count += 1
                dmf_logger.info("********************************* published #{count} families for job with job_id #{job.job_id} *********************************") if count % 100 == 0
              else
                dmf_logger.error("Family with id #{family.id} is missing hbx_assigned_id -- unable to proceed with dmf determination")
              end
            rescue StandardError => e
              dmf_logger.error("Failed to process for family with hbx_id #{family&.hbx_assigned_id} due to #{e.inspect}")
            end

            Success('Published all dmf-eligible family hbx_ids')
          end

          def build_event(payload)
            event('events.families.verifications.dmf_determination.started', attributes: payload)
          end

          def publish(payload)
            event = build_event(payload)
            event.success.publish

            Success("Successfully published dmf determination payload")
          end

          def dmf_logger
            @dmf_logger ||= Logger.new("#{Rails.root}/log/dmf_logger_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
          end
        end
      end
    end
  end
end