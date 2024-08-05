# frozen_string_literal: true

# This script takes a string of comma separated hbx_ids and initiates the force sync operation.

# Command to trigger the script:
#   CLIENT=me bundle exec rails runner script/crm/trigger_force_sync.rb 'hbx_id1, hbx_id2, hbx_id3'

# Checks if the :async_publish_updated_families feature is enabled in the EnrollRegistry.
# If the feature is not enabled, it prints a message and exits the script.
#
# @return [void]
unless EnrollRegistry.feature_enabled?(:async_publish_updated_families)
  puts 'The CRM Sync Refactor feature is not enabled. Please enable the feature :async_publish_updated_families to run this script. EXITING.'
  exit
end

# Creates an array of hbx_ids from the input string and removes any nil values, spaces or empty strings.
# @example
#   bundle exec rails runner script/crm/trigger_force_sync.rb 'hbx_id1, hbx_id2, hbx_id3'
# @param [String] ARGV[0] a comma separated list of HBX IDs
# @return [void]
primary_person_hbx_ids = begin
  # The below line splits the input string by comma, removes any leading or trailing spaces, converts the values to string, and rejects any empty strings.
  ARGV[0].split(',').map { |hbx_id| hbx_id.strip.to_s }.reject(&:empty?)
rescue StandardError => e
  puts "Error: #{e.message}. Invalid input for primary_hbx_ids: #{ARGV[0]}. Provide a comma separated list of HBX IDs."
  exit
end

# Initiates the force sync operation with the provided HBX IDs.
# @param [Array<String>] primary_hbx_ids an array of HBX IDs
# @return [void]
result = ::Operations::Crm::ForceSync.new.call({ primary_hbx_ids: primary_person_hbx_ids })
if result.success?
  puts result.success
else
  puts result.failure
end
