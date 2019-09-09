module TransportProfiles
  module Processes
    class PushReportEligibilityUpdatedH41 < ::TransportProfiles::Processes::Process

      def initialize(source_uri, gateway, destination_file_name: d_file_name, source_credentials: s_credentials)
        super("Distribute eligibility updated H41", gateway)

        add_step(TransportProfiles::Steps::RouteTo.new(:report_eligibility_updated_h41s, source_uri, gateway, destination_file_name: destination_file_name, source_credentials: source_credentials))
      end

      def self.used_endpoints
        [
          :report_eligibility_updated_h41s
        ]
      end
    end
  end
end
