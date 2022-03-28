# frozen_string_literal: true

module ClientReporting
  module Dc
    module FinancialAssistanceAuditReport
      # Writes Application and payloads to CSV format.
      class ReportSerializer
        HEADERS = [
          "Enroll Application ID",
          # "Fin App ID",
          # "Haven App ID",
          # "Haven IC ID",
          "Submitted At",
          "Family ID",
          "Primary Member ID",
          "Member ID",
          "Relationship",
          "First Name",
          "Middle Name",
          "Last Name",
          "Name Suffix",
          "Date of Birth",
          "Home Address Street 1",
          "Home Address Street 2",
          "Home Address City",
          "Home Address State",
          "Home Address Zip",
          "Mailing Address Street 1",
          "Mailing Address Street 2",
          "Mailing Address City",
          "Mailing Address State",
          "Mailing Address Zip",
          "Temporarily Out of State",
          "Is Homeless",
          "Citizen Status",
          "Is Incarcerated",
          "Indian Tribe Member",
          "Applying for Coverage",
          "Is Insurance Assistance Eligible",
          "Is Medicaid CHIP Eligible"
        ].freeze

        def process(csv_file, query)
          csv_file << HEADERS
          query.each do |result|
            field_sets = fields_from(result)
            field_sets.each do |fields|
              values = HEADERS.map { |a| fields[a] }
              csv_file << values
            end
          end
        end

        # rubocop:disable Style/EmptyLiteral
        def fields_from(application)
          req_extractor = request_extractor_for(application)
          resp_extractor = ResponsePayloadExtractor.new(application)
          result_fields = Array.new
          req_ex_field_sets = req_extractor.field_sets
          resp_ex_field_sets = resp_extractor.field_sets
          req_ex_field_sets.each do |fs|
            resp_fields = resp_ex_field_sets.detect do |ref|
              ref["Member ID"] == fs["Member ID"]
            end
            resp_fields = resp_fields.nil? ? {} : resp_fields
            result_fields << fs.merge(resp_fields)
          end
          result_fields
        end
        # rubocop:enable Style/EmptyLiteral

        def request_extractor_for(application)
          if application.eligibility_request_payload.blank?
            RequestApplicationExtractor.new(application)
          else
            RequestPayloadExtractor.new(application)
          end
        end
      end
    end
  end
end