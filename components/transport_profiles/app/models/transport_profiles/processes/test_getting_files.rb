module TransportProfiles
  class Processes::TestGettingFiles < Processes::Process
    def initialize(gateway)
      super("Distribute system generated employee terminations report", gateway)
      list_step = TransportProfiles::Steps::ListEntries.new(:aca_shop_analytics_outbound, :file_list, gateway) do |entries|
        entries.any? ? [entries.sort_by(&:mtime).last] : []
      end
      add_step(list_step)
      add_step(TransportProfiles::Steps::RouteTo.new(:aca_legacy_data_extracts, :file_list, gateway, source_credentials: :aca_shop_analytics_outbound))
    end

    def self.run_test
      gateway = TransportGateway::Gateway.new(nil, Rails.logger)
      process = self.new(gateway)
      process.execute
    end

    def self.used_endpoints
      []
    end
  end
end
