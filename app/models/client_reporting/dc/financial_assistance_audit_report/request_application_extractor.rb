# frozen_string_literal: true

module ClientReporting
  module Dc
    module FinancialAssistanceAuditReport
      # Extracts data fields from the application itself in the cases where
      # the request payload may not have been loged.
      class RequestApplicationExtractor
        def initialize(application)
          @financial_assistance_application = application
        end

        def field_sets
          extract_from_application
        end

        # rubocop:disable Style/EmptyLiteral
        def extract_from_application
          result_fields = Array.new
          primary_applicant = @financial_assistance_application.applicants.detect(&:is_primary_applicant)
          primary_applicant_id = primary_applicant ? primary_applicant.person_hbx_id : nil
          @financial_assistance_application.applicants.each do |applicant|
            fields = Hash.new.merge(
              {
                "Enroll Application ID" => @financial_assistance_application.id,
                "Fin App ID" => @financial_assistance_application.hbx_id,
                "Haven App ID" => @financial_assistance_application.haven_app_id,
                "Haven IC ID" => @financial_assistance_application.haven_ic_id,
                "Submitted At" => @financial_assistance_application.submitted_at,
                "Family ID" => @financial_assistance_application.family_id
              }
            )
            fields["Primary Member ID"] = primary_applicant_id
            fields["Member ID"] = applicant.person_hbx_id
            fields["Is Homeless"] = applicant.is_homeless
            fields["Citizen Status"] = applicant.citizen_status
            fields["First Name"] = applicant.first_name
            fields["Middle Name"] = applicant.middle_name
            fields["Last Name"] = applicant.last_name
            fields["Name Suffix"] = applicant.name_sfx
            fields["Date of Birth"] = applicant.dob
            fields["Is Incarcerated"] = applicant.is_incarcerated
            fields["Indian Tribe Member"] = applicant.indian_tribe_member
            fields["Applying for Coverage"] = applicant.is_applying_coverage
            fields["Temporarily Out of State"] = applicant.is_temporarily_out_of_state
            fields["Relationship"] = resolve_relationship(primary_applicant, applicant)
            fields = extract_address_information(fields)
            result_fields << fields
          end
          result_fields
        end
        # rubocop:enable Style/EmptyLiteral

        def extract_address_information(fields, applicant)
          include_home_address = fields.merge(extract_home_address(applicant))
          include_home_address.merge(extract_mailing_address(applicant))
        end

        def extract_home_address(applicant)
          fields = {}
          home_address = applicant.addresses.detect do |addy|
            addy.kind == "home"
          end
          if home_address
            fields["Home Address Street 1"] = home_address.address_1
            fields["Home Address Street 2"] = home_address.address_2
            fields["Home Address City"] = home_address.city
            fields["Home Address State"] = home_address.state
            fields["Home Address Zip"] = home_address.zip
          end
          fields
        end

        def extract_mailing_address(applicant)
          fields = {}
          mailing_address = applicant.addresses.detect do |addy|
            addy.kind == "mailing"
          end
          if mailing_address
            fields["Mailing Address Street 1"] = mailing_address.address_1
            fields["Mailing Address Street 2"] = mailing_address.address_2
            fields["Mailing Address City"] = mailing_address.city
            fields["Mailing Address State"] = mailing_address.state
            fields["Mailing Address Zip"] = mailing_address.zip
          end
          fields
        end

        def resolve_relationship(primary_applicant, applicant)
          return "self" if primary_applicant.person_hbx_id == applicant.person_hbx_id
          return "unrelated" unless primary_applicant
          relationship = @financial_assistance_application.relationships.detect do |rel|
            (rel.applicant_id == applicant.id) &&
              (rel.relative_id == primary_applicant.id)
          end
          return "unrelated" unless relationship
          relationship.kind
        end
      end
    end
  end
end
