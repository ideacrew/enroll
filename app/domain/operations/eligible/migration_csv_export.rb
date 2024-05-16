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
      include Dry::Monads[:do, :result]

      # @param [Hash] opts Options to build eligibility
      # @option opts [<String>]   :resource_name required
      # @option opts [<String>]   :filename required
      # @option opts [<String>]   :eligibility_type required
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
          "#{values[:filename]}#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv",
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
              csv << (
                [
                  (subject.try(:hbx_id) || subject.id),
                  record["eligibility_type"],
                  record["start_on"],
                  record["created_at"],
                  record["updated_at"],
                  evidence["is_satisfied"],
                  evidence["created_at"],
                  evidence["updated_at"]
                ] + matched_eligibility_fields(subject, record, evidence)
              )
            end
          end
      end

      def fields
        [
          "Subject Hbx ID",
          "Subject Type",
          "Old Eligibility Start Date",
          "Old Eligibility Created At",
          "Old Eligibility Update At",
          "Old Evidence Satisfied",
          "Old Evidence Created At",
          "Old Evidence Updated At",
          "Eligibility SH Effective On",
          "Eligibility SH Is Eligible",
          "Eligibility SH To State",
          "Eligibility SH Transition At",
          "Eligibility SH Created At",
          "Eligibility SH Updated At",
          "Evidence SH Effective On",
          "Evidence SH Is Eligible",
          "Evidence SH To State",
          "Evidence SH Transition At",
          "Evidence SH Created At",
          "Evidence SH Updated At"
        ]
      end

      def matched_eligibility_fields(subject, record, evidence_hash)
        eligibility = subject.eligibilities.detect do |e|
          e.eligibility_period_cover?(record["start_on"].to_date)
        end

        return [] unless eligibility

        eligibility_state_history =
          find_matched_state_history(
            evidence_hash,
            record["start_on"].to_date,
            eligibility
          )
        evidence_state_history =
          find_matched_state_history(
            evidence_hash,
            record["start_on"].to_date,
            eligibility.evidences.last
          )

        state_history_fields(eligibility_state_history) +
          state_history_fields(evidence_state_history)
      end

      def state_history_fields(history)
        %i[
          effective_on
          is_eligible
          to_state
          transition_at
          created_at
          updated_at
        ].collect { |field| history&.send(field) }
      end

      def find_matched_state_history(evidence_hash, start_on, record = nil)
        return unless record
        record.state_histories.detect do |sh|
          sh.transition_at == evidence_hash["updated_at"] &&
            sh.is_eligible.to_s == evidence_hash["is_satisfied"].to_s &&
            sh.effective_on == start_on
        end
      end
    end
  end
end
