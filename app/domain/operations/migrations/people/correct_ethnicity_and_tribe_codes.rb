# frozen_string_literal: true

module Operations
  module Migrations
    module People
      # This class is responsible for correcting the ethnicity and tribe codes for people.
      class CorrectEthnicityAndTribeCodes
        include Dry::Monads[:do, :result]

        # Initiates the correction process.
        #
        # @return [Dry::Monads::Result::Success, Dry::Monads::Result::Failure]
        def call
          people  = yield fetch_eligible_people
          result  = yield correct_data(people)

          Success(result)
        end

        private

        # Fetches people who are eligible for correction.
        #
        # @return [Dry::Monads::Result::Success<Array<Person>>] A list of eligible people.
        def fetch_eligible_people
          Success(
            Person.where(
              :$or => [
                { :tribe_codes => { :$exists => false } },
                { :tribe_codes => nil },
                { :ethnicity => { :$exists => false } },
                { :ethnicity => nil }
              ]
            )
          )
        end

        # Corrects the data for the given people and generates a CSV report.
        #
        # @param people [Array<Person>] The list of people to correct.
        # @return [Dry::Monads::Result::Success<String>] A success message with the path to the report.
        def correct_data(people)
          csv_file = "#{Rails.root}/correct_ethnicity_and_tribe_codes_for_people_report.csv"
          CSV.open(csv_file, 'w', force_quotes: true) do |csv|
            csv << ['Person HBX ID', 'Updated Information', 'Error']

            people.each do |person|
              updated_info = {}

              updated_info[:ethnicity] = [] if person.read_attribute(:ethnicity).nil?
              updated_info[:tribe_codes] = [] if person.read_attribute(:tribe_codes).nil?

              unless updated_info.empty?
                updated_info[:updated_at] = Time.now.utc
                person.set(updated_info)
                csv << [person.hbx_id, updated_info, '']
              end
            rescue StandardError => e
              csv << [person.hbx_id, '', e.message]
            end
          end

          Success(
            "Successfully corrected the ethnicity and tribe codes for all the people. Please check the report: #{csv_file} for more details."
          )
        end
      end
    end
  end
end
