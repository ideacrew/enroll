# frozen_string_literal: true

module Operations
  module HbxEnrollments
    # Publish events to begin IVL enrollment coverages
    class BeginCoverageHandler
      include EventSource::Command
      include Dry::Monads[:result, :do]

      def initialize
        @logger = Logger.new("#{Rails.root}/log/hbx_enrollments_begin_coverage_handler_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
      end

      # @param [Hash] params
      # @option params [String] :query_criteria
      # @return [Dry::Monads::Result]
      def call(params)
        query_criteria = yield validate(params)
        enrollments_to_begin = yield enrollments_to_begin_query(query_criteria)
        result                = yield publish_enrollment_expirations(enrollments_to_begin)

        Success(result)
      end

      private

      def validate(params)
        return Failure('Missing query_criteria') unless params.key?(:query_criteria)

        Success(params[:query_criteria])
      end

      def enrollments_to_begin_query(query_criteria)
        enrollments_to_begin = HbxEnrollment.where(query_criteria)
        # evaluating the criteria here to ensure the query is valid
        enrollments_to_begin.count

        Success(enrollments_to_begin)
      rescue StandardError => e
        Failure("Error generating enrollments_to_begin query: #{e.message}; with query criteria: #{query_criteria}")
      end

      def publish_enrollment_expirations(enrollments_to_expire)
        enrollments_to_expire.no_timeout.each_with_index do |enrollment, index|
          enrollment_hbx_id = enrollment.hbx_id
          event = event("events.individual.enrollments.begin_coverages.begin", attributes: { enrollment_hbx_id: enrollment_hbx_id, index_id: index})
          publish_event(event)
        end
        Success("Done publishing begin coverage enrollment events.  See hbx_enrollments_begin_coverage_handler log for results.")
      end

      def publish_event(event)
        if event.success?
          @logger.info "Publishing begin coverage event for enrollment hbx id: #{enrollment_hbx_id}"
          event.success.publish
        else
          @logger.error "ERROR - Publishing begin coverage event failed for enrollment hbx id: #{enrollment_hbx_id}"
        end
      end
    end
  end
end
