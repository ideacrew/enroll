# frozen_string_literal: true

# This script triggers the benchmark premiums migration for all the applications.

# Command to trigger the script:
#   CLIENT=me bundle exec rails runner script/applications/populate_benchmark_premiums.rb '1000'

# @example Run the script with a batch size of 1000
#   CLIENT=me bundle exec rails runner script/applications/populate_benchmark_premiums.rb '1000'
#
# @param [Integer] batch_size the size of the batch to process
# @return [void]
batch_size = begin
  ARGV[0].to_i
rescue StandardError => e
  p "Error: #{e.message}. Invalid input for batch_size: #{ARGV[0]}. Please provide a positive integer. Exiting..."
  exit
end

# Initiates the process to populate benchmark premiums with a specified batch size.
#
# @param batch_size [Integer] the size of the batch to process
# @return [void]
result = Operations::Migrations::Applications::BenchmarkPremiums::Initiate.new.call({ batch_size: batch_size })
if result.success?
  p result.success
else
  p result.failure
end
