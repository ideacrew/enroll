# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Reports
    class GeneratePreauditReconsilationReport
      include EventSource::Command
      send(:include, Dry::Monads[:result, :do])

      def call
        event = yield build_event
        result = yield publish(event)

        Success(result)
      end

      private

      def build_event
        event("events.enroll.reports.preaudit_generation_report")
      end

      def publish(event)
        event.publish
      end
    end
  end
end
