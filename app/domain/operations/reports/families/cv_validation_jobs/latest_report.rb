# frozen_string_literal: true

module Operations
  module Reports
    module Families
      module CvValidationJobs
        # This class generates the latest CV Validation Job report.
        class LatestReport
          include Dry::Monads[:do, :result]

          # Generates the latest CV Validation Job report.
          #
          # @return [Dry::Monads::Result::Success<String>, Dry::Monads::Result::Failure<String>]
          def call
            job_id        = yield fetch_latest_job_id
            logger_name   = yield fetch_logger_name(job_id)
            logger        = yield generate_log_file(logger_name)
            jobs          = yield fetch_cv_validation_jobs(job_id)
            csv_file_name = yield fetch_csv_file_name(job_id)
            message       = yield process_jobs(csv_file_name, jobs, logger, logger_name)

            Success(message)
          end

          private

          # Fetches the latest job ID.
          #
          # @return [Dry::Monads::Result::Success<Integer>, Dry::Monads::Result::Failure<String>]
          def fetch_latest_job_id
            latest_job_id = CvValidationJob.latest_job_id

            if latest_job_id.present?
              Success(latest_job_id)
            else
              Failure('No CV Validation Job found')
            end
          end

          # Fetches the logger name based on the job ID.
          #
          # @param job_id [Integer] The job ID.
          # @return [Dry::Monads::Result::Success<String>, Dry::Monads::Result::Failure<String>]
          def fetch_logger_name(job_id)
            Success(
              "#{Rails.root}/latest_cv_validation_job_logger_#{job_id}_#{DateTime.now.strftime('%Y_%m_%d_%H_%M_%S')}.log"
            )
          end

          # Generates the log file for the report.
          #
          # @param logger_name [String] The logger file name.
          # @return [Dry::Monads::Result::Success<Logger>, Dry::Monads::Result::Failure<String>]
          def generate_log_file(logger_name)
            Success(Logger.new(logger_name))
          end

          # Fetches CV validation jobs by job ID.
          #
          # @param job_id [Integer] The job ID.
          # @return [Dry::Monads::Result::Success<Array<CvValidationJob>>, Dry::Monads::Result::Failure<String>]
          def fetch_cv_validation_jobs(job_id)
            Success(
              CvValidationJob.by_job_id(job_id).only(
                :primary_person_hbx_id,
                :family_hbx_id,
                :family_updated_at,
                :job_id,
                :result,
                :cv_errors,
                :cv_start_time,
                :cv_end_time
              )
            )
          end

          # Generates the CSV file name for the report.
          #
          # @param job_id [Integer] The job ID.
          # @return [Dry::Monads::Result::Success<String>, Dry::Monads::Result::Failure<String>]
          def fetch_csv_file_name(job_id)
            Success(
              "#{Rails.root}/latest_cv_validation_job_report_#{job_id}_#{DateTime.now.strftime('%Y_%m_%d_%H_%M_%S')}.csv"
            )
          end

          # Processes the jobs and generates the CSV report.
          #
          # @param csv_file_name [String] The CSV file name.
          # @param jobs [Array<CvValidationJob>] The CV validation jobs.
          # @param logger [Logger] The log file.
          # @param logger_name [String] The logger file name.
          # @return [Dry::Monads::Result::Success<String>, Dry::Monads::Result::Failure<String>]
          def process_jobs(csv_file_name, jobs, logger, logger_name)
            CSV.open(csv_file_name, 'w', force_quotes: true) do |csv|
              csv << [
                'Primary Person HBX ID',
                'Family HBX ID',
                'Family Updated At',
                'Job Id',
                'Result',
                'CV Errors',
                'CV Payload Transform Time',
              ]

              jobs.each do |job|
                logger.info "Processing job: #{job.job_id}"

                csv << [
                  job.primary_person_hbx_id,
                  job.family_hbx_id,
                  job.family_updated_at,
                  job.job_id,
                  job.result,
                  job.cv_errors,
                  job.cv_payload_transformation_time
                ]

                logger.info "Processed job: #{job.job_id}"
              rescue StandardError => e
                logger.error "Error processing job: #{job.job_id} - #{e.message}"
              end
            end

            Success(
              "Latest CV Validation Job report generated: #{csv_file_name} and log file: #{logger_name}"
            )
          end
        end
      end
    end
  end
end
