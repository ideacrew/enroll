module TransportProfiles
  module Processes
    class Legacy::PushGlueEnrollmentReport < ::TransportProfiles::Processes::Process

      def initialize(source_uri, gateway, destination_file_name: destination_file_name, source_credentials: source_credentials)
        super("Distribute remote glue legacy enrollment report", gateway)

        add_step(TransportProfiles::Steps::RouteTo.new(:aca_legacy_data_extracts_archive, source_uri, gateway, destination_file_name: destination_file_name, source_credentials: source_credentials))
        add_step(TransportProfiles::Steps::RouteTo.new(:aca_legacy_data_extracts, source_uri, gateway, destination_file_name: destination_file_name, source_credentials: source_credentials))
      end
    end
  end
end
