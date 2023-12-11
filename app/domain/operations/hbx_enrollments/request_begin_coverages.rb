# frozen_string_literal: true

module Operations
    module HbxEnrollments
      # Publish event to request coverage initiation of all IVL renewal enrollments for the new year
      class RequestBeginCoverages
        include EventSource::Command
        include Dry::Monads[:result, :do]

      # @param [Hash] opts The options to request initiation of all IVL renewal enrollments for the new year
      # @option opts [Hash] :params
      # @return [Dry::Monads::Result]
      def call(_params)
        logger         = yield initialize_logger
        query_criteria = yield fetch_query_critiria
        event          = yield build_event(query_criteria)
        result         = yield publish(event, logger)

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

      def start_on
        @start_on ||= HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period.start_on
      end

      def end_on
        @start_on ||= HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period.end_on
      end

      # TODO: Remove hard coded aaasm_state and kind values.
      #       Define constants for them in HbxEnrollment class and use them.
      def fetch_query_critiria
        Success(
            {
                "effective_on": { "$gte": start_on, "$lt": end_on },
                "kind": { "$in": ["individual", "coverall"] },
                "aasm_state": { "$in": ["auto_renewing", "renewing_coverage_selected"] }
              }
        )
      end

      def build_event(query_criteria)
        event(
          'events.individual.enrollments.begin_coverages.request',
          attributes: {
            query_criteria: query_criteria
          }
        )
      end

      def publish(event, logger)
        event.publish
        msg = "Successfully published event: #{event.name} to request beginning coverage for all IVL renewal enrollments effective on #{start_on}."
        logger.info(msg)
        Success(msg)
      end
      end
    end
end