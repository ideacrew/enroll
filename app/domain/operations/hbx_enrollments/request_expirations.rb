# frozen_string_literal: true

module Operations
  module HbxEnrollments
    # Publish event to request expiration of all active IVL enrollments for the previous years
    class RequestExpirations
      include EventSource::Command
      include Dry::Monads[:result, :do]

      # @param [Hash] opts The options to request expiration all active IVL enrollments for the previous years
      # @option opts [Hash] :params
      # @return [Dry::Monads::Result]
      def call(params)
        logger         = yield initialize_logger
        job            = yield create_job
        query_criteria = yield fetch_query_critiria
        event          = yield build_event(fetch_query_critiria, job)
        result         = yield publish(event, logger)

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

      def start_on
        @start_on ||= HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period.start_on
      end

      def create_job
        ::Operations::Transmittable::CreateJob.new.call(
          {
            key: :hbx_enrollments_expiration,
            title: "Request expiration of all active IVL enrollments before #{start_on}.",
            description: "Job that requests expiration of all active IVL enrollments before #{start_on}.",
            publish_on: DateTime.now,
            started_at: DateTime.now,
          }
        )
      end

      # TODO: Remove hard coded aaasm_state and kind values.
      #       Define constants for them in HbxEnrollment class and use them.
      def fetch_query_critiria
        Success(
          {
            'aasm_state': { '$in': HbxEnrollment::ENROLLED_STATUSES - ['coverage_termination_pending'] },
            'effective_on': { '$lt': start_on },
            'kind': { '$in': ['individual', 'coverall'] }
          }
        )
      end

      def build_event(query_criteria, job)
        event(
          'events.individual.enrollments.expire_coverages.request',
          attributes: {
            query_criteria: query_criteria,
            transmittable_identifiers: { job_gid: job.to_global_id.uri }
          }
        )
      end

      def publish(event, logger)
        event.publish
        msg = "Successfully published event: #{event.name} to request expiration of all active IVL enrollments effective before #{start_on}."
        logger.info(msg)
        Success(msg)
      end
    end
  end
end
