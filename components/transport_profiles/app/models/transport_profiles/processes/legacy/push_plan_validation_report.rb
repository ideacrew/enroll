# frozen_string_literal: true

module TransportProfiles
  module Processes
    module Legacy
      class PushPlanValidationReport < Processes::Process
        def initialize(report_file_name, gateway)
          super("Distribute system generated legacy cca plan validation report", gateway)
          @report_file_name = report_file_name

          add_step(TransportProfiles::Steps::RouteTo.new(:aca_shop_analytics_archive, report_file_name, gateway))
          add_step(TransportProfiles::Steps::RouteTo.new(:aca_shop_analytics_outbound, report_file_name, gateway))
          add_step(TransportProfiles::Steps::DeleteFile.new(report_file_name, gateway))
        end

        def self.used_endpoints
          [
            :aca_shop_analytics_archive,
            :aca_shop_analytics_outbound
          ]
        end
      end
    end
  end
end
