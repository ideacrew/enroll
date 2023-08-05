# frozen_string_literal: true

require "dry/monads"
require "dry/monads/do"

# Operations::Eligible::MigrationCsvExport.new.call(
#   eligibility_type: "BenefitSponsors::BenefitSponsorships::BenefitSponsorship",
#   resource_name: "Eligibilities::Osse::Eligibility",
#   filename: "osse_eligibilities_export"
# )

module Operations
  module Eligible
    # Operation to export migrated eligibilities
    class MigrationCsvExport
      send(:include, Dry::Monads[:result, :do])

      # @param [Hash] opts Options to build eligibility
      # @option opts [<String>]   :resource_name required
      # @option opts [<Array>]   :filename required
      # @return [Dry::Monad] result
      def call(params)
        values = yield validate(params)
        grouped_records = yield find_groups(values)
        file_name = yield export(grouped_records, values)

        Success(file_name)
      end

      private

      def validate(params)
        errors = []
        errors << "file name missing" unless params[:filename]

        if params[:resource_name].present?
          params[:resource] = params[:resource_name].constantize
        else
          errors << "eligibility class missing"
        end
        errors << "eligibility type required" unless params[:eligibility_type]

        errors.empty? ? Success(params) : Failure(errors)
      end

      def find_groups(values)
        grouped_records =
          values[:resource].collection.aggregate(
            [
              {
                "$match" => {
                  eligibility_type: /#{values[:eligibility_type]}/i
                }
              },
              {
                "$group": {
                  _id: "$subject.key",
                  records: {
                    "$push": "$$ROOT"
                  }
                }
              }
            ]
          )

        Success(grouped_records)
      end

      def export(records, values)
        CSV.open(
          "#{values[:filename]}#{TimeKeeper.date_of_record.strftime("%m_%d_%Y")}.csv",
          "w"
        ) do |csv|
          csv << fields
          records.each { |record| process_entry(csv, record) }
        end

        Success(true)
      end

      def process_entry(csv, entry)
        subject = GlobalID::Locator.locate(entry["_id"])
        entry["records"]
          .sort_by { |record| record["created_at"].to_i }
          .each do |record|
            record["evidences"].each do |evidence|
              csv << [
                subject.hbx_id,
                record["eligibility_type"],
                record["start_on"],
                record["created_at"],
                record["updated_at"],
                evidence["is_satisfied"],
                evidence["created_at"],
                evidence["updated_at"]
              ]
            end
          end
      end

      def fields
        [
          "Subject Hbx ID",
          "Subject Type",
          "Start Date",
          "Eligibility Created At",
          "Eligibility Update At",
          "Evidence Satisfied",
          "Evidence Created At",
          "Evidence Updated At"
        ]
      end
    end
  end
end
