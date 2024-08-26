# frozen_string_literal: true

require 'gem_utils'

module Operations
  module Private
    module Families
      # Class responsible for validating CV for a family
      class ValidateCv
        include Dry::Monads[:do, :result]
        include GemUtils

        # Main method to call the validation process
        # @param params [Hash] the parameters for validation
        # @option params [String] :family_hbx_id the family HBX ID
        # @option params [Time] :family_updated_at the time the family was updated
        # @option params [String] :job_id the job ID
        # @return [Dry::Monads::Result] the result of the validation process
        def call(params)
          family_hbx_id             = yield validate_params(params)
          family                    = yield find_family(family_hbx_id)
          _transform_results        = yield transform_to_entity(family)
          cv_validation_job_params  = yield construct_cv_validation_job_params(family, family_hbx_id)
          cv_validation_job         = yield create_cv_validation_job(cv_validation_job_params)

          Success(cv_validation_job)
        end

        private

        # Validates the input parameters
        # @param params [Hash] the parameters to validate
        # @option params [String] :family_hbx_id the family HBX ID
        # @option params [Time] :family_updated_at the time the family was updated
        # @option params [String] :job_id the job ID
        # @return [Dry::Monads::Result] the result of the validation
        def validate_params(params)
          @job_monotonic_start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

          if params.is_a?(Hash) && params[:family_hbx_id].present? && params[:family_updated_at].present? && params[:job_id].present?
            @family_updated_at = params[:family_updated_at].to_datetime
            @job_id = params[:job_id]

            Success(params[:family_hbx_id])
          else
            Failure("Invalid input parameters: #{params}. Expected keys with values: family_hbx_id, family_updated_at, and job_id.")
          end
        rescue StandardError => e
          Failure("Error validating input parameters: #{params}. Error Message: #{e.message}")
        end

        # Finds the family by HBX ID
        # @param family_hbx_id [String] the family HBX ID
        # @return [Dry::Monads::Result] the result of the find operation
        def find_family(family_hbx_id)
          family = ::Family.where(hbx_assigned_id: family_hbx_id).first

          if family
            Success(family)
          else
            Failure("Unable to find family with hbx_id: #{family_hbx_id}")
          end
        end

        # Transforms the family to an entity
        # @param family [Family] the family object
        # @return [Dry::Monads::Result] the result of the transformation
        #
        # @note This method always returns a success result, even if the transformation fails for storing the result and error message in the job.
        def transform_to_entity(family)
          @cv_monotonic_start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          result = Operations::Families::TransformToEntity.new.call(family)
          @cv_monotonic_end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

          @transform_result = result.success? ? result.success[0] : result.failure[0]
          @json_family_entity = result.success? ? result.success[1].to_json : nil
          @cv_errors = result.failure? ? [result.failure[1]] : nil

          result.success? ? result : Success(nil)
        end

        # Constructs the CV validation job parameters
        # @param family [Family] the family object
        # @param family_hbx_id [String] the family HBX ID
        # @return [Dry::Monads::Result] the result of the construction
        def construct_cv_validation_job_params(family, family_hbx_id)
          Success(
            {
              cv_payload: @json_family_entity,
              cv_version: 3,
              aca_version: AcaEntities::VERSION,
              aca_entities_sha: GemUtils.aca_entities_sha,
              primary_person_hbx_id: family.primary_person&.hbx_id,
              family_hbx_id: family_hbx_id,
              family_updated_at: @family_updated_at,
              job_id: @job_id,
              result: @transform_result,
              cv_errors: @cv_errors,
              cv_payload_transformation_time: @cv_monotonic_end_time - @cv_monotonic_start_time,
              job_elapsed_time: Process.clock_gettime(Process::CLOCK_MONOTONIC) - @job_monotonic_start_time
            }
          )
        end

        # Creates the CV validation job
        # @param cv_validation_job_params [Hash] the parameters for the CV validation job
        # @return [Dry::Monads::Result] the result of the creation
        def create_cv_validation_job(cv_validation_job_params)
          Success(CvValidationJob.create!(cv_validation_job_params))
        end
      end
    end
  end
end
