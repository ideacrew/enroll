# frozen_string_literal: true

# This class is used to persist the results of the CV Validation Job for each family per Job.
class CvValidationJob
  include Mongoid::Document
  include Mongoid::Timestamps

  # @!attribute [rw] cv_payload
  #   @return [String] The JSON payload that is generated for each Family transform.
  field :cv_payload, type: String

  # @!attribute [rw] cv_version
  #   @return [String] The version of the CV Schema that was used to validate the CV. The current Canonical Version is 3.
  field :cv_version, type: String

  # @!attribute [rw] aca_version
  #   @return [String] The version of the aca_entities gem that was used to validate the CV. This version changes with each release of the aca_entities gem.
  field :aca_version, type: String

  # @!attribute [rw] aca_entities_sha
  #   @return [String] The SHA of the aca_entities gem that was used to validate the CV.
  field :aca_entities_sha, type: String

  # @!attribute [rw] family_hbx_id
  #   @return [String] This is the identifier that is used to identify the Family in the Enroll System.
  field :family_hbx_id, type: String

  # @!attribute [rw] family_updated_at
  #   @return [DateTime] Updated at timestamp of the Family at the time of the CV Validation Job.
  #   This might not have a great value as of now as the CV Payload also contains information from other collections but this is here as a placeholder for future enhancements/use.
  field :family_updated_at, type: DateTime

  # @!attribute [rw] job_id
  #   @return [String] This field is for identifying the Job. There is no Job persisted but this attribute acts as an identifier to group the results of the CV Validation Job per trigger.
  field :job_id, type: String

  # @!attribute [rw] result
  #   @return [Symbol] The result of the CV Validation Job. This can be one of the following: :success - The CV Validation Job was successful. :failure - The CV Validation Job failed.
  field :result, type: Symbol

  # @!attribute [rw] cv_errors
  #   @return [Array<String>] The errors that were encountered during the CV Validation Job.
  field :cv_errors, type: Array

  # @!attribute [rw] logging_messages
  #   @return [Array<String>] The messages that were logged during the CV Validation Job. This is a placeholder for future enhancements/use.
  field :logging_messages, type: Array

  # @!attribute [rw] cv_start_time
  #   @return [DateTime] The start timestamp to track how long the CV payload took to generate.
  field :cv_start_time, type: DateTime

  # @!attribute [rw] cv_end_time
  #   @return [DateTime] The end timestamp to track how long the CV payload took to generate.
  field :cv_end_time, type: DateTime

  # @!attribute [rw] start_time
  #   @return [DateTime] The start timestamp of the CV Validation Job.
  field :start_time, type: DateTime

  # @!attribute [rw] end_time
  #   @return [DateTime] The end timestamp of the CV Validation Job.
  field :end_time, type: DateTime

  # Scopes

  # @!scope class

  # Scope to get all records with a result of success.
  # @return [Mongoid::Criteria] Criteria for querying successful CV Validation Jobs.
  scope :success, -> { where(result: :success) }

  # Scope to get all records with a result of failure.
  # @return [Mongoid::Criteria] Criteria for querying failed CV Validation Jobs.
  scope :failure, -> { where(result: :failure) }

  # Scope to get all records by job ID.
  # @param job_id [String] The job ID to filter by.
  # @return [Mongoid::Criteria] Criteria for querying CV Validation Jobs by job ID.
  scope :by_job_id, ->(job_id) { where(job_id: job_id) }

  # Scope to get all records by family HBX ID.
  # @param family_hbx_id [String] The family HBX ID to filter by.
  # @return [Mongoid::Criteria] Criteria for querying CV Validation Jobs by family HBX ID.
  scope :by_family_hbx_id, ->(family_hbx_id) { where(family_hbx_id: family_hbx_id) }

  # Scope to get the latest records ordered by creation date.
  # @return [Mongoid::Criteria] Criteria for querying the latest CV Validation Jobs.
  scope :latest, -> { order(created_at: :desc) }

  # Indexes

  # Index on the result field to optimize queries filtering by result.
  # @return [Mongoid::Index] Index on the result field.
  index({ result: 1 }, { name: 'result_index' })

  # Index on the job_id field to optimize queries filtering by job ID.
  # @return [Mongoid::Index] Index on the job_id field.
  index({ job_id: 1 }, { name: 'job_id_index' })

  # Index on the family_hbx_id field to optimize queries filtering by family HBX ID.
  # @return [Mongoid::Index] Index on the family_hbx_id field.
  index({ family_hbx_id: 1 }, { name: 'family_hbx_id_index' })

  # Index on the created_at field to optimize queries filtering by creation date.
  # @return [Mongoid::Index] Index on the created_at field.
  index({ created_at: 1 }, { name: 'created_at_index' })

  # Calculates the time taken to create the CV payload.
  #
  # @return [Integer, nil] The difference in seconds between cv_end_time and cv_start_time, or nil if either is not set.
  def cv_payload_creation_time
    duration_in_seconds(cv_end_time, cv_start_time)
  end

  # Calculates the time taken for the CV validation job.
  #
  # @return [Integer, nil] The difference in seconds between end_time and start_time, or nil if either is not set.
  def cv_validation_job_time
    duration_in_seconds(end_time, start_time)
  end

  private

  # Calculates the difference in seconds between two DateTime objects.
  #
  # @param end_datetime [DateTime] The end time.
  # @param start_datetime [DateTime] The start time.
  # @return [Integer, nil] The difference in seconds between end_datetime and start_datetime, or nil if either is not set.
  def duration_in_seconds(end_datetime, start_datetime)
    return nil unless start_datetime && end_datetime

    ((end_datetime - start_datetime) * 24 * 60 * 60).to_i
  end

  class << self
    # Returns the job ID of the latest job.
    #
    # @return [Integer, nil] the job ID of the latest job, or nil if there are no jobs.
    def latest_job_id
      latest.first&.job_id
    end
  end
end
