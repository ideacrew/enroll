# frozen_string_literal: true

module Operations
  module HbxEnrollments
    # Publish events to begin IVL enrollment coverages
    class BeginCoverageHandler
      include EventSource::Command
      include Dry::Monads[:do, :result]

      attr_reader :job, :logger

      # @param [Hash] params
      # @option params [Hash] :query_criteria, :transmittable_identifiers
      # @return [Dry::Monads::Result]
      # @example params: {
      #   query_criteria: {
      #     'aasm_state': { '$in': ['auto_renewing', 'renewing_coverage_selected'] },
      #     'effective_on': { '$gte': start_on, '$lt': end_on },
      #     'kind': { '$in': ['individual', 'coverall'] }
      #   },
      #   transmittable_identifiers: {
      #     job_gid: 'gid://enroll/Transmittable::Job/65739e355b4dc03a97f26c3b'
      #   }
      # }
      def call(params)
        @logger              = yield initialize_logger
        values               = yield validate(params)
        @job                 = yield find_job(values[:transmittable_identifiers][:job_gid])
        enrollments_to_begin = yield enrollments_to_begin_query(values[:query_criteria])
        result               = yield publish_enrollment_initiations(enrollments_to_begin)

        Success(result)
      end

      private

      def initialize_logger
        Success(
          Logger.new(
            "#{Rails.root}/log/hbx_enrollments_begin_coverages_handler_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
          )
        )
      end

      def validate(params)
        unless params.is_a?(Hash)
          msg = "Invalid input params: #{params}. Expected a hash."
          logger.error msg
          return Failure(msg)
        end

        unless params[:query_criteria].is_a?(Hash)
          msg = "Invalid query_criteria in params: #{params}. Expected a hash."
          logger.error msg
          return Failure(msg)
        end

        unless params[:transmittable_identifiers].is_a?(Hash)
          msg = "Invalid transmittable_identifiers in params: #{params}. Expected a hash."
          logger.error msg
          return Failure(msg)
        end

        if params[:transmittable_identifiers][:job_gid].blank?
          msg = "Missing job_gid in transmittable_identifiers of params: #{params}."
          logger.error msg
          return Failure(msg)
        end

        Success(params)
      end

      def find_job(job_gid)
        job = GlobalID::Locator.locate(job_gid)

        if job.present?
          logger.info "Found Transmittable::Job with given id: #{job_gid}"
          Success(job)
        else
          msg = "No Transmittable::Job found with given id: #{job_gid}"
          logger.error msg
          Failure(msg)
        end
      end

      def enrollments_to_begin_query(query_criteria)
        enrollments_to_begin = HbxEnrollment.where(query_criteria)

        if enrollments_to_begin.present?
          Success(enrollments_to_begin)
        else
          failure_msg = "No enrollments found for query criteria: #{query_criteria}"
          logger.error failure_msg
          Failure(failure_msg)
        end
      rescue StandardError => e
        Failure("Error generating enrollments_to_begin query: #{e.message}; with query criteria: #{query_criteria}")
      end

      def publish_enrollment_initiations(enrollments_to_begin)
        enrollments_to_begin.no_timeout.each do |enrollment|
          result = ::Operations::HbxEnrollments::PublishBeginCoverageEvent.new.call(
            { enrollment: enrollment, job: job }
          )

          if result.success?
            logger.info result.success
          else
            logger.error "Failed to publish begin coverage event for enrollment hbx id: #{enrollment.hbx_id}"
          end
        end

        success_msg = 'Done publishing enrollment begin coverage events. See hbx_enrollments_begin_coverages_handler log for results.'
        logger.info success_msg
        Success(success_msg)
      end
    end
  end
end
