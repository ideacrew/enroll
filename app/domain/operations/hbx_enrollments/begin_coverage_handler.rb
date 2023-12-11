# frozen_string_literal: true

module Operations
  module HbxEnrollments
    # Publish events to begin IVL enrollment coverages
    class BeginCoverageHandler
      include EventSource::Command
      include Dry::Monads[:result, :do]

      # @param [Hash] params
      # @option params [Hash] :query_criteria
      # @return [Dry::Monads::Result]
      def call(params)
        query_criteria       = yield validate(params)
        enrollments_to_begin = yield enrollments_to_begin_query(query_criteria)
        result               = yield publish_enrollment_initiations(enrollments_to_begin)

        Success(result)
      end

      private

      def validate(params)
        return Failure('Missing query_criteria.') unless params.is_a?(Hash) && params[:query_criteria].is_a?(Hash)

        Success(params[:query_criteria])
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
          # TODO: use global id instead of hbx_id
          result = Operations::HbxEnrollments::PublishBeginCoverageEvent.new.call({enrollment_hbx_id: enrollment.hbx_id})
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
