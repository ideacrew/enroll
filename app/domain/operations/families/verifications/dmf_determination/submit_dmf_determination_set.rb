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
            submit_for_dmf_determination(families)

            Success("Successfully Submitted DMF Set")
          end

          private

          def query_families_with_active_members
            return Failure('ALIVE_STATUS is not enabled for this env') unless EnrollRegistry.feature_enabled?(:alive_status)

            families = Family.enrolled_members_with_ssn
            Success(families)
          end

          def submit_for_dmf_determination(families)
            count = 0

            families.each do |family|
              values = build_family_transmittable_values(family)

              if values.present?
                job = create_job(values)
                publish({ family_hbx_id: family.hbx_assigned_id, job_id: job.job_id })

                count += 1
                started_dmf_logger.info("********************************* published #{count} families *********************************") if count % 100 == 0
              else
                started_dmf_logger.error("Family with id #{family.id} is missing hbx_assigned_id -- unable to proceed with dmf determination")
              end
            rescue StandardError => e
              started_dmf_logger.error("Failed to process for family with hbx_id #{family&.hbx_assigned_id} due to #{e.inspect}")
            end
          end

          def build_family_transmittable_values(family)
            return unless family&.hbx_assigned_id

            {
              key: :started_dmf_determination,
              title: 'Started DMF Determination',
              description: 'Initialized DMF Determination for individual Family',
              correlation_id: family.hbx_assigned_id,
              started_at: DateTime.now,
              publish_on: DateTime.now
            }
          end

          def build_event(payload)
            event('events.families.verifications.dmf_determination.started', attributes: payload)
          end

          def publish(payload)
            event = build_event(payload)
            event.success.publish

            Success("Successfully published dmf determination payload")
          end

          def started_dmf_logger
            @started_dmf_logger ||= Logger.new("#{Rails.root}/log/started_dmf_logger_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
          end
        end
      end
    end
  end
end
