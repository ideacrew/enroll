# frozen_string_literal: true

# This script takes a string of the issuer profile id and initiates the remove products operation.

# Command to trigger the script:
# CLIENT=me bundle exec rails runner script/products/remove_products.rb '123456780f5040', '2025-01-01'

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

year = date.year
products = BenefitMarkets::Products::Product.by_year(year).where(:issuer_profile_id => ARGV[0])

result = ::Operations::Products::RemoveProducts.new.call({ date: date, products: products })

if result.success?
  puts result.success
else
  puts result.failure
end