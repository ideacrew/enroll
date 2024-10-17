# frozen_string_literal: true

module Operations
  module Migrations
    module Applicants
      # This class is responsible for correcting ethnicity and tribe codes for applicants.
      # It fetches eligible applications and updates the data accordingly.
      class CorrectEthnicityAndTribeCodes
        include Dry::Monads[:do, :result]

        # Initiates the correction process.
        #
        # @return [Dry::Monads::Result::Success, Dry::Monads::Result::Failure] the result of the correction process
        def call
          applications  = yield fetch_eligible_applications
          result        = yield correct_data(applications)

          Success(result)
        end

        private

        # Fetches applications that have applicants with missing ethnicity or tribe codes.
        #
        # @return [Dry::Monads::Result::Success<Array<FinancialAssistance::Application>>] the eligible applications
        def fetch_eligible_applications
          Success(
            ::FinancialAssistance::Application.where(
              :applicants => {
                :$exists => true,
                :$elemMatch => {
                  :$or => [
                    { :tribe_codes => { :$exists => false } },
                    { :tribe_codes => nil },
                    { :ethnicity => { :$exists => false } },
                    { :ethnicity => nil }
                  ]
                }
              }
            )
          )
        end

        # Corrects the data for the given applications and generates a CSV report.
        #
        # @param applications [Array<FinancialAssistance::Application>] the applications to correct
        # @return [Dry::Monads::Result::Success<String>] the success message with the report path
        def correct_data(applications)
          csv_file = "#{Rails.root}/correct_ethnicity_and_tribe_codes_for_applicants_report.csv"

          CSV.open(csv_file, 'w', force_quotes: true) do |csv|
            csv << ['Application HBX ID', 'Applicant HBX ID', 'Updated Information', 'Error']

            applications.each do |application|
              application.applicants.each do |applicant|
                updated_info = {}

                updated_info[:ethnicity] = [] if applicant.read_attribute(:ethnicity).nil?
                updated_info[:tribe_codes] = [] if applicant.read_attribute(:tribe_codes).nil?

                unless updated_info.empty?
                  updated_info[:updated_at] = Time.now.utc
                  applicant.set(updated_info)
                  csv << [application.hbx_id, applicant.person_hbx_id, updated_info, '']
                end
              rescue StandardError => e
                csv << [application.hbx_id, applicant.person_hbx_id, '', e.message]
              end
            end
          end

          Success(
            "Successfully corrected the ethnicity and tribe codes for all the applicants. Please check the report: #{csv_file} for more details."
          )
        end
      end
    end
  end
end
