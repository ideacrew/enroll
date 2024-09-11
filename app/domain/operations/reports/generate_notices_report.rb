# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Reports
    # Gets the people who has documents created in a specified date range and
    # inserts those document information into a CSV file.
    # Defaults to current day if no range is specified.
    class GenerateNoticesReport
      include Dry::Monads[:result, :do]

      def call(params)
        values            = yield validate(params)
        people            = yield fetch_people(values)
        report_status     = yield generate_report(people, values)

        Success(report_status)
      end

      private

      def validate(params)
        start_date = params[:start_date].present? ? Date.strptime(params[:start_date].to_s, "%m/%d/%Y").beginning_of_day : TimeKeeper.date_of_record.beginning_of_day
        end_date = params[:end_date].present? ? Date.strptime(params[:end_date].to_s, "%m/%d/%Y").end_of_day : TimeKeeper.date_of_record.end_of_day

        Success(params.merge!(start_date: start_date, end_date: end_date))
      end

      def fetch_people(values)
        people = Person.where(
          :documents => {
            :$elemMatch => {
              :created_at.gte => values[:start_date],
              :created_at.lte => values[:end_date]
            }
          }
        )

        Success(people)
      end

      def fetch_notice_report_file_name
        "notices_list_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.csv"
      end

      def fetch_notice_report_headers
        ['HBX ID', 'Notice Title', 'Notice Code', 'Date']
      end

      def notices_title_code_mapping
        {
          "Welcome to CoverME.gov!" => "IVLMWE",
          "Your Plan Enrollment" => "IVLENR",
          "Your Eligibility Results - Tax Credit" => "IVLERA",
          "Your Eligibility Results - MaineCare or Cub Care" => "IVLERM",
          "Your Eligibility Results - Marketplace Health Insurance" => "IVLERQ",
          "Your Eligibility Results - Marketplace Insurance" => "IVLERU",
          "Open Enrollment - Tax Credit" => "IVLOEA",
          "Open Enrollment - Update Your Application" => "IVLOEM",
          "Your Eligibility Results - Health Coverage Eligibility" => "IVLOEQ",
          "Open Enrollment - Marketplace Insurance" => "IVLOEU",
          "Your Eligibility Results Consent or Missing Information Needed" => "IVLOEG",
          "Find Out If You Qualify For Health Insurance On CoverME.gov" => "IVLMAT",
          "Your Plan Enrollment for 2022" => "IVLFRE",
          "Action Needed - Submit Documents" => "IVLDR0",
          "Reminder - You Must Submit Documents" => "IVLDR1",
          "Don't Forget - You Must Submit Documents" => "IVLDR2",
          "Don't Miss the Deadline - You Must Submit Documents" => "IVLDR3",
          "Final Notice - You Must Submit Documents" => "IVLDR4"
        }
      end

      def generate_report(people, values)
        CSV.open(fetch_notice_report_file_name, 'w+', headers: true) do |csv|
          csv << fetch_notice_report_headers
          people.each do |person|
            documents = person.documents.where(:created_at.gte => values[:start_date])
            documents.each do |document|
              puts [person.hbx_id, document.title, notices_title_code_mapping[document.title], document.created_at] unless Rails.env.test?
              csv << [person.hbx_id, document.title, notices_title_code_mapping[document.title], document.created_at]
            end
          end
        rescue StandardError => e
          Failure("Error generating report: #{e.message}")
        end

        Success("Generated Notices report successfully")
      end
    end
  end
end