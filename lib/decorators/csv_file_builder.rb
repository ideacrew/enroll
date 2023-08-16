# frozen_string_literal: true

module Decorators
  # CSV file builder to build report
  class CSVFileBuilder
    def initialize(filename, headers)
      @output = CSV.open(filename, "w")

      append_data(headers)
    rescue StandardError => e
      @logger.error "Error: Failed in initialize CSVFileBuilder #{e.message}, backtrace: #{e.backtrace}"
    end

    def append_data(data)
      @output.add_row(data)
      @output.flush
    rescue StandardError => e
      @logger.error "Error: Failed in append_data CSVFileBuilder #{e.message}, backtrace: #{e.backtrace}"
    end
  end
end
