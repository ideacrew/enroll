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
          enrollment_hbx_id = enrollment.hbx_id
          event = event("events.individual.enrollments.begin_coverages.begin", attributes: { enrollment_hbx_id: enrollment_hbx_id })
          publish_event(event, enrollment_hbx_id)
        end
        Success("Done publishing enrollment expiration events. See hbx_enrollments_expiration_handler log for results.")
      end

      def publish_event(event, enrollment_hbx_id)
        if event.success?
          handler_logger.info "Publishing begin coverage event for enrollment hbx id: #{enrollment_hbx_id}"
          event.success.publish
        else
          handler_logger.error "ERROR - Publishing begin coverage event failed for enrollment hbx id: #{enrollment_hbx_id}"
        end
      end

      def handler_logger
        @handler_logger ||= Logger.new("#{Rails.root}/log/hbx_enrollments_begin_coverage_handler_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
      end
    end
  end
end
