# frozen_string_literal: true

module Operations
  module HbxEnrollments
    # Publish events to expire IVL enrollment coverages
    class ExpirationHandler
      include EventSource::Command
      include Dry::Monads[:do, :result]

      attr_reader :job, :logger

      # @param [Hash] params
      # @option params [Hash] :query_criteria, :transmittable_identifiers
      # @return [Dry::Monads::Result]
      # @example params: {
      #   query_criteria: {
      #     'aasm_state': { '$in': HbxEnrollment::ENROLLED_STATUSES - ['coverage_termination_pending'] },
      #     'effective_on': { '$lt': start_on },
      #     'kind': { '$in': ['individual', 'coverall'] }
      #   },
      #   transmittable_identifiers: {
      #     job_gid: 'gid://enroll/Transmittable::Job/65739e355b4dc03a97f26c3b'
      #   }
      # }
      def call(params)
        @logger               = yield initialize_logger
        values                = yield validate(params)
        @job                  = yield find_job(values[:transmittable_identifiers][:job_gid])
        enrollments_to_expire = yield enrollments_to_expire_query(values[:query_criteria])
        result                = yield publish_enrollment_expirations(enrollments_to_expire)

        Success(result)
      end

      private

      def initialize_logger
        Success(
          Logger.new(
            "#{Rails.root}/log/hbx_enrollments_expiration_handler_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
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

      def enrollments_to_expire_query(query_criteria)
        enrollments_to_expire = HbxEnrollment.where(query_criteria)

        if enrollments_to_expire.present?
          Success(enrollments_to_expire)
        else
          failure_msg = "No enrollments found for query criteria: #{query_criteria}"
          logger.error failure_msg
          Failure(failure_msg)
        end
      rescue StandardError => e
        Failure("Error generating enrollments_to_expire query: #{e.message}; with query criteria: #{query_criteria}")
      end

      def publish_enrollment_expirations(enrollments_to_expire)
        enrollments_to_expire.no_timeout.each do |enrollment|
          result = ::Operations::HbxEnrollments::PublishExpirationEvent.new.call(
            { enrollment: enrollment, job: job }
          )

          if result.success?
            logger.info result.success
          else
            logger.error "Failed to publish expiration event for enrollment hbx id: #{enrollment.hbx_id}"
          end
        end

        success_msg = 'Done publishing enrollment expiration events. See hbx_enrollments_expiration_handler log for results.'
        logger.info success_msg
        Success(success_msg)
      end
    end
  end
end
