# frozen_string_literal: true

module Operations
  module Private
    module Families
      module BulkCvValidation
        # Request class handles the bulk CV validation process for families.
        # It fetches families, generates a job ID, processes the families, and publishes events.
        class Request
          include Dry::Monads[:do, :result]
          include EventSource::Command

          VALIDATE_CV_EVENT_NAME = 'events.private.families.validate_cv_requested'

          # Initiates the bulk CV validation process.
          #
          # @return [Dry::Monads::Result::Success, Dry::Monads::Result::Failure]
          def call
            families = yield fetch_families
            job_id   = yield generate_job_id
            logger   = yield create_logger(job_id)
            message  = yield process_families(families, job_id, logger)

            Success(message)
          end

          private

          # Fetches the families to be validated.
          #
          # @return [Dry::Monads::Result::Success<Array<Family>>]
          def fetch_families
            Success(::Family.only(:_id, :hbx_assigned_id, :updated_at))
          end

          # Generates a unique job ID.
          #
          # @return [Dry::Monads::Result::Success<String>]
          def generate_job_id
            Success(SecureRandom.uuid)
          end

          # Creates a logger instance for the job.
          #
          # @param job_id [String] the job ID
          # @return [Dry::Monads::Result::Success<Logger>]
          def create_logger(job_id)
            Success(Logger.new("#{Rails.root}/bulk_cv_validation_logger_#{job_id}.log"))
          end

          # Processes the families and publishes events.
          #
          # @param families [Array<Family>] the families to be processed
          # @param job_id [String] the job ID
          # @param logger [Logger] the logger instance
          # @return [Dry::Monads::Result::Success]
          def process_families(families, job_id, logger)
            file_name = "#{Rails.root}/bulk_cv_validation_report_#{job_id}.csv"

            CSV.open(file_name, 'w', force_quotes: true) do |csv|
              csv << ['Family HBX ID', 'Family Updated At', 'Job ID', 'Publish Result']

              families.each do |family|
                logger.info "***** Processing family hbx_assigned_id: #{family.hbx_assigned_id}"
                csv << build_and_publish_event(family, job_id, logger)
                logger.info "***** Processed family hbx_assigned_id: #{family.hbx_assigned_id}"
              end
            end

            msg = "----- Events triggered for all the families. CSV file named #{file_name} is generated with the results. -----"
            logger.info msg
            Success(msg)
          end

          # Builds and publishes an event for a family.
          #
          # @param family [Family] the family to build and publish the event for
          # @param job_id [String] the job ID
          # @param logger [Logger] the logger instance
          # @return [Array<String, Time, String, String>] the event details and publish result
          def build_and_publish_event(family, job_id, logger)
            ev_event = event(
              VALIDATE_CV_EVENT_NAME,
              attributes: {
                family_hbx_id: family.hbx_assigned_id,
                family_updated_at: family.updated_at,
                job_id: job_id
              }
            )

            if ev_event.success?
              ev_event.success.publish
              logger.info "Successfully published event: #{VALIDATE_CV_EVENT_NAME} for family hbx_assigned_id: #{family.hbx_assigned_id}"
              [family.hbx_assigned_id, family.updated_at, job_id, 'Success']
            else
              logger.error "Failed to build event: #{VALIDATE_CV_EVENT_NAME} for family hbx_assigned_id: #{family.hbx_assigned_id}"
              [family.hbx_assigned_id, family.updated_at, job_id, 'Failed']
            end
          end
        end
      end
    end
  end
end
