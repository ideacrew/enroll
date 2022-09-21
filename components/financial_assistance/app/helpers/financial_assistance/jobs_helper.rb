# frozen_string_literal: true

module FinancialAssistance
  # Helper for "event source" jobs
  module JobsHelper
    def process_start_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def process_end_time_formatted(start_time)
      end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      seconds_elapsed = end_time - start_time
      format("%02dhr %02dmin %02dsec", seconds_elapsed / 3600, seconds_elapsed / 60 % 60, seconds_elapsed % 60)
    end
  end
end