# frozen_string_literal: true

module Operations
  module HbxEnrollments
    # Publish events to begin IVL enrollment coverages
    class BeginCoverageHandler
      include EventSource::Command
      include Dry::Monads[:result, :do]

      attr_reader :job

      # @param [Hash] params
      # @option params [Hash] :query_criteria, :transmittable_identifiers
      # @return [Dry::Monads::Result]
      # @example params: {
      #   query_criteria: {
      #     "effective_on": { "$gte": start_on, "$lt": end_on },
      #      "kind": { "$in": ["individual", "coverall"] },
      #      "aasm_state": { "$in": HbxEnrollment::RENEWAL_STATUSES - ["renewing_coverage_enrolled"] }
      #    }
      #   transmittable_identifiers: {
      #     job_gid: 'gid://enroll/Transmittable::Job/65739e355b4dc03a97f26c3b'
      #   }
      # }
      def call(params)
        query_criteria       = yield validate(params)
        @job                 = yield find_job(values[:transmittable_identifiers][:job_gid])
        enrollments_to_begin = yield enrollments_to_begin_query(query_criteria)
        result               = yield publish_enrollment_initiations(enrollments_to_begin)

        Success(result)
      end

      private

      def validate(params)
        unless params.is_a?(Hash)
          msg = "Invalid input params: #{params}. Expected a hash."
          return Failure(msg)
        end

        unless params[:query_criteria].is_a?(Hash)
          msg = "Invalid query_criteria in params: #{params}. Expected a hash."
          return Failure(msg)
        end

        unless params[:transmittable_identifiers].is_a?(Hash)
          msg = "Invalid transmittable_identifiers in params: #{params}. Expected a hash."
          return Failure(msg)
        end

        if params[:transmittable_identifiers][:job_gid].blank?
          msg = "Missing job_gid in transmittable_identifiers of params: #{params}."
          return Failure(msg)
        end

        Success(params)
      end

      def find_job(job_gid)
        job = GlobalID::Locator.locate(job_gid)

        if job.present?
          Success(job)
        else
          msg = "No Transmittable::Job found with given id: #{job_gid}"
          Failure(msg)
        end
      end

      def enrollments_to_begin_query(query_criteria)
        enrollments_to_begin = HbxEnrollment.where(query_criteria)

        if enrollments_to_begin.present?
          Success(enrollments_to_begin)
        else
          Failure("No enrollments found for query criteria: #{query_criteria}")
        end
      rescue StandardError => e
        Failure("Error generating enrollments_to_begin query: #{e.message}; with query criteria: #{query_criteria}")
      end

      def publish_enrollment_initiations(enrollments_to_begin)
        enrollments_to_begin.no_timeout.each do |enrollment|
          result = Operations::HbxEnrollments::PublishBeginCoverageEvent.new.call({enrollment: enrollment})
          if result.success?
            handler_logger.info "Enrollment hbx id: #{enrollment.hbx_id} - #{result.success}"
          else
            handler_logger.error "Enrollment hbx id: #{enrollment.hbx_id} - #{result.failure}"
          end
        end
        Success("Done publishing begin coverage enrollment events. See hbx_enrollments_begin_coverage_handler log for results.")
      end

      def handler_logger
        @handler_logger ||= Logger.new("#{Rails.root}/log/hbx_enrollments_begin_coverage_handler_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
      end
    end
  end
end
