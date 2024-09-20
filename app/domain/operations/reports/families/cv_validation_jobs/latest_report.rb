# frozen_string_literal: true

module Operations
  module Reports
    module Families
      module CvValidationJobs
        # This class generates the latest CV Validation Job report.
        #
        # It validates the input parameters, fetches the necessary data,
        # processes the jobs, and generates CSV reports and log files.
        class LatestReport
          include Dry::Monads[:do, :result]

          # Generates the latest CV Validation Job report.
          #
          # @param params [Hash] The parameters for generating the report.
          # @option params [Integer] :jobs_per_iteration The number of jobs to process per iteration.
          # @return [Dry::Monads::Result::Success<String>, Dry::Monads::Result::Failure<String>]
          def call(params)
            @logger_name        = yield fetch_logger_name
            @logger             = yield generate_log_file
            @jobs_per_iteration = yield validate(params)
            @job_id             = yield fetch_latest_job_id
            @jobs               = yield fetch_cv_validation_jobs
            @csv_field_names    = yield fetch_csv_field_names
            message             = yield generate_report

            Success(message)
          end

          private

          # Fetches the logger name based on the job ID.
          #
          # @return [Dry::Monads::Result::Success<String>, Dry::Monads::Result::Failure<String>]
          def fetch_logger_name
            Success(
              "#{Rails.root}/latest_cv_validation_job_logger_#{DateTime.now.strftime('%Y_%m_%d_%H_%M_%S')}.log"
            )
          end

          # Generates the log file for the report.
          #
          # @return [Dry::Monads::Result::Success<Logger>, Dry::Monads::Result::Failure<String>]
          def generate_log_file
            Success(Logger.new(@logger_name))
          end

          # Validates the parameters.
          #
          # @param params [Hash] The parameters to validate.
          # @option params [Integer] :jobs_per_iteration The number of jobs to process per iteration.
          # @return [Dry::Monads::Result::Success<Integer>, Dry::Monads::Result::Failure<String>]
          def validate(params)
            if params[:jobs_per_iteration].to_i < 0
              failure_msg = "Invalid jobs_per_iteration: #{params[:jobs_per_iteration]}. Please pass jobs_per_iteration as a positive integer."
              @logger.error failure_msg
              Failure(failure_msg)
            else
              @logger.info "Validating jobs_per_iteration: #{params[:jobs_per_iteration]}."
              Success(params[:jobs_per_iteration].to_i)
            end
          end

          # Fetches the latest job ID.
          #
          # @return [Dry::Monads::Result::Success<Integer>, Dry::Monads::Result::Failure<String>]
          def fetch_latest_job_id
            latest_job_id = CvValidationJob.latest_job_id

            if latest_job_id.present?
              @logger.info "Latest CV Validation Job ID: #{latest_job_id}."
              Success(latest_job_id)
            else
              msg = 'No CV Validation Job found'
              @logger.error msg
              Failure(msg)
            end
          end

          # Fetches CV validation jobs by job ID.
          #
          # @return [Dry::Monads::Result::Success<Array<CvValidationJob>>, Dry::Monads::Result::Failure<String>]
          def fetch_cv_validation_jobs
            Success(
              CvValidationJob.by_job_id(@job_id).order(:_id.asc).only(
                :_id,
                :primary_person_hbx_id,
                :family_hbx_id,
                :family_updated_at,
                :job_id,
                :result,
                :cv_errors,
                :cv_payload_transformation_time
              )
            )
          end

          # Fetches the CSV field names.
          #
          # @return [Dry::Monads::Result::Success<Array<String>>, Dry::Monads::Result::Failure<String>]
          def fetch_csv_field_names
            Success(
              [
                'Primary Person HBX ID',
                'Family HBX ID',
                'Family Updated At',
                'Job Id',
                'Result',
                'CV Errors',
                'CV Payload Transformation Time'
              ]
            )
          end

          # Processes the jobs and writes them to a CSV file.
          #
          # @param counter [Integer] The current iteration counter.
          # @return [void]
          def process_jobs(counter)
            offset_count = @jobs_per_iteration * counter
            file_name = "#{Rails.root}/latest_cv_validation_job_report_#{@job_id}_#{counter.next}_#{DateTime.now.strftime('%Y_%m_%d_%H_%M_%S')}.csv"

            @logger.info "---- Processing jobs from offset: #{offset_count} and limit: #{@jobs_per_iteration}"

            CSV.open(file_name, 'w', force_quotes: true) do |csv|
              csv << @csv_field_names
              @logger.info "Writing to CSV: #{file_name}."

              @jobs.skip(offset_count).limit(@jobs_per_iteration).each do |job|
                @logger.info "Processing job: #{job.id}"

                csv << [
                  job.primary_person_hbx_id,
                  job.family_hbx_id,
                  job.family_updated_at,
                  job.job_id,
                  job.result,
                  job.cv_errors,
                  job.cv_payload_transformation_time
                ]

                @logger.info "Processed job: #{job.job_id}"
              rescue StandardError => e
                @logger.error "Error processing job: #{job.job_id} - #{e.message}"
              end
            end
          end

          # Generates the report by processing jobs in iterations.
          #
          # @return [Dry::Monads::Result::Success<String>, Dry::Monads::Result::Failure<String>]
          def generate_report
            total_jobs = @jobs.count
            number_of_iterations = (total_jobs / @jobs_per_iteration.to_f).ceil
            counter = 0

            while counter < number_of_iterations
              process_jobs(counter)
              counter += 1
            end

            Success(
              "Latest CV Validation Job report generated with multiple CSVs named 'latest_cv_validation_job_report_#{@job_id}_*.csv' and log file: #{@logger_name}"
            )
          end
        end
      end
    end
  end
end
