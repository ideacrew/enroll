# frozen_string_literal: true

# This script takes a string of the carrier legal name and a date and initiates the remove products operation.

# Command to trigger the script:
# CLIENT=me bundle exec rails runner script/products/remove_products.rb 'XYZ Carrier', '2025-01-01'

unless ARGV[0].present? && ARGV[1].present?
  puts 'Missing Arguments'
  exit
end

date = begin
  ARGV[1].to_date
rescue StandardError => e
  puts "Error: #{e.message}. Invalid date"
  exit
end

carrier = ARGV[0]

result = ::Operations::Products::RemoveProducts.new.call({ date: date, carrier: carrier })

if result.success?
  puts result.success
else
  puts result.failure
end