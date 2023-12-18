# frozen_string_literal: true

module Operations
  module HbxEnrollments
    # Publish event to request expiration of all active IVL enrollments for the previous years
    class RequestExpirations
      include ::Operations::Transmittable::TransmittableUtils

      attr_reader :job, :logger

      # @param [Hash] opts The options to request expiration all active IVL enrollments for the previous years
      # @option opts [Hash] :params
      # @return [Dry::Monads::Result]
      def call(_params)
        @logger        = yield initialize_logger
        bcp_start_on   = yield fetch_bcp_start_on
        job_params     = yield construct_job_params(bcp_start_on)
        @job           = yield create_job(job_params)
        query_criteria = yield fetch_query_criteria(bcp_start_on)
        event          = yield build_event(query_criteria)
        result         = yield publish(bcp_start_on, event)

        Success(result)
      end

      private

      def initialize_logger
        Success(
          Logger.new(
            "#{Rails.root}/log/request_expirations_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
          )
        )
      end

      def fetch_bcp_start_on
        start_on = HbxProfile.current_hbx&.benefit_sponsorship&.current_benefit_coverage_period&.start_on

        if start_on.present?
          Success(start_on)
        else
          Failure('Unable to find the start_on date for current benefit coverage period.')
        end
      end

      def construct_job_params(bcp_start_on)
        Success(
          {
            key: :hbx_enrollments_expiration,
            title: "Request expiration of all active IVL enrollments before #{bcp_start_on}.",
            description: "Job that requests expiration of all active IVL enrollments before #{bcp_start_on}.",
            publish_on: DateTime.now,
            started_at: DateTime.now
          }
        )
      end

      # TODO: Remove hard coded aasm_state and kind values.
      #       Define constants for them in HbxEnrollment class and use them.
      def fetch_query_criteria(bcp_start_on)
        Success(
          {
            'aasm_state': { '$in': HbxEnrollment::ENROLLED_STATUSES - ['coverage_termination_pending'] },
            'effective_on': { '$lt': bcp_start_on },
            'kind': { '$in': ['individual', 'coverall'] }
          }
        )
      end

      def build_event(query_criteria)
        event(
          'events.individual.enrollments.expire_coverages.request',
          attributes: {
            query_criteria: query_criteria,
            transmittable_identifiers: { job_gid: job.to_global_id.uri }
          }
        )
      end

      def publish(bcp_start_on, event)
        event.publish
        msg = "Successfully published event: #{event.name} to request expiration of all active IVL enrollments effective before #{bcp_start_on}."
        logger.info(msg)
        Success(msg)
      end
    end
  end
end
