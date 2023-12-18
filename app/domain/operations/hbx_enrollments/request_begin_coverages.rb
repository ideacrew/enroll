# frozen_string_literal: true

module Operations
  module HbxEnrollments
    # Publish event to request coverage initiation of all IVL renewal enrollments for the current year
    class RequestBeginCoverages
      include ::Operations::Transmittable::TransmittableUtils

      attr_reader :job, :logger

      # @param [Hash] opts The options to request initiation of all IVL renewal enrollments for the current year
      # @option opts [Hash] :params
      # @return [Dry::Monads::Result]
      def call(_params)
        @logger          = yield initialize_logger
        start_on, end_on = yield fetch_start_on_and_end_on
        job_params       = yield construct_job_params(start_on)
        @job             = yield create_job(job_params)
        query_criteria   = yield fetch_query_criteria(start_on, end_on)
        event            = yield build_event(query_criteria)
        result           = yield publish(event, start_on)

        Success(result)
      end

      private

      def initialize_logger
        Success(
          Logger.new(
            "#{Rails.root}/log/request_begin_coverages_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
          )
        )
      end

      def fetch_start_on_and_end_on
        bcp = HbxProfile.current_hbx&.benefit_sponsorship&.current_benefit_coverage_period

        if bcp.present? && bcp.start_on.present? && bcp.end_on.present?
          Success([bcp.start_on, bcp.end_on])
        else
          Failure('Unable to find start_on and end_on for the current benefit coverage period.')
        end
      end

      def construct_job_params(start_on)
        Success(
          {
            key: :hbx_enrollments_begin_coverage,
            title: "Request begin coverage of all renewal IVL enrollments for the year #{start_on.year}.",
            description: "Job that requests begin coverage of all renewal IVL enrollments before #{start_on.year}.",
            publish_on: DateTime.now,
            started_at: DateTime.now
          }
        )
      end

      # TODO: Remove hard coded aaasm_state and kind values.
      #       Define constants for them in HbxEnrollment class and use them.
      def fetch_query_criteria(start_on, end_on)
        Success(
          {
            'aasm_state': { '$in': ['auto_renewing', 'renewing_coverage_selected'] },
            'effective_on': { '$gte': start_on, '$lt': end_on },
            'kind': { '$in': ['individual', 'coverall'] }
          }
        )
      end

      def build_event(query_criteria)
        event(
          'events.individual.enrollments.begin_coverages.request',
          attributes: {
            query_criteria: query_criteria,
            transmittable_identifiers: { job_gid: job.to_global_id.uri }
          }
        )
      end

      def publish(event, start_on)
        event.publish
        msg = "Successfully published event: #{event.name} to request begin coverage for all IVL renewal enrollments for the year #{start_on.year}."
        logger.info(msg)
        Success(msg)
      end
    end
  end
end
