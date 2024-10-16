# frozen_string_literal: true

# This script triggers the correction of ethnicity and tribe_codes for all the people.

# Command to trigger the script:
#   CLIENT=me bundle exec rails runner script/people/correct_ethnicity_and_tribe_codes.rb

result = ::Operations::Migrations::People::CorrectEthnicityAndTribeCodes.new.call

if result.success?
  p result.success
else
  p result.failure
end
