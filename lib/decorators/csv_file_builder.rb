# frozen_string_literal: true

module Decorators
  # CSV file builder to build report
  class CSVFileBuilder
    def initialize(file_path, headers, logger)
      @file_path = file_path
      @logger = logger
      # creates the file and add headers
      CSV.open(file_path, "w") do |csv|
        csv << headers
      end
    rescue StandardError => e
      @logger.error "Error: Failed in initialize CSVFileBuilder #{e.message}, backtrace: #{e.backtrace}"
    end

    def append_data(rows)
      CSV.open(@file_path, 'a') do |csv|
        rows.each do |row|
          csv << row
        end
      end
    rescue StandardError => e
      @logger.error "Error: Failed in append_data CSVFileBuilder #{e.message}, backtrace: #{e.backtrace}"
    end
  end
end
