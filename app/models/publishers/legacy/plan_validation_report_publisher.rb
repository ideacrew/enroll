# frozen_string_literal: true

module Publishers
  module Legacy
    class PlanValidationReportPublisher
      attr_reader :gateway
      def initialize
        @gateway = TransportGateway::Gateway.new(nil, Rails.logger)
      end

      def publish(file_uri)
        process = TransportProfiles::Processes::Legacy::PushPlanValidationReport.new(file_uri, @gateway)
        process.execute
      end
    end
  end
end
