# frozen_string_literal: true

module ClientReporting
  module Dc
    module FinancialAssistanceAuditReport
      # Encapsulates the report
      class Report
        def initialize(csv_p, query_params)
          @csv_path = csv_p
          @query_parameters = query_params
        end

        def run!
          serializer = ReportSerializer.new
          query = Query.new(@query_parameters)
          query.prepare
          CSV.open(@csv_path, "wb") do |csv|
            serializer.process(csv, query)
          end
        end

        def self.run_fy_2021_report
          report = ClientReporting::Dc::FinancialAssistanceAuditReport::Report.new(
            "example_report.csv",
            {
              :submitted_at => {
                "$gte" => Time.new(2020,9,30),
                "$lt" => Time.new(2021,10,1,4)
              }
            }
          )
          report.run!
        end
      end
    end
  end
end