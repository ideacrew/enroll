# frozen_string_literal: true

module ClientReporting
  module Dc
    module FinancialAssistanceAuditReport
      # Extracts data fields from the request payload.
      class RequestPayloadExtractor
        FIELD_MAPPINGS = {
          "Last Name" => ".//cv:person_name/cv:person_surname",
          "First Name" => ".//cv:person_name/cv:person_given_name",
          "Middle Name" => ".//cv:person_name/cv:person_middle_name",
          "Name Suffix" => ".//cv:person_name/cv:person_name_suffix_text",
          "Date of Birth" => ".//cv:person_demographics/cv:birth_date",
          "Applying for Coverage" => ".//cv:is_coverage_applicant",
          "Home Address Street 1" =>
            "cv:individual/cv:person/cv:addresses/cv:address/cv:type[contains(text(),'urn:openhbx:terms:v1:address_type#home')]/../cv:address_line_1",
          "Home Address Street 2" =>
            "cv:individual/cv:person/cv:addresses/cv:address/cv:type[contains(text(),'urn:openhbx:terms:v1:address_type#home')]/../cv:address_line_2",
          "Home Address City" =>
            "cv:individual/cv:person/cv:addresses/cv:address/cv:type[contains(text(),'urn:openhbx:terms:v1:address_type#home')]/../cv:location_city_name",
          "Home Address State" =>
            "cv:individual/cv:person/cv:addresses/cv:address/cv:type[contains(text(),'urn:openhbx:terms:v1:address_type#home')]/../cv:location_state_code",
          "Home Address Zip" =>
            "cv:individual/cv:person/cv:addresses/cv:address/cv:type[contains(text(),'urn:openhbx:terms:v1:address_type#home')]/../cv:postal_code",
          "Mailing Address Street 1" =>
            "cv:individual/cv:person/cv:addresses/cv:address/cv:type[contains(text(),'urn:openhbx:terms:v1:address_type#mailing')]/../cv:address_line_1",
          "Mailing Address Street 2" =>
            "cv:individual/cv:person/cv:addresses/cv:address/cv:type[contains(text(),'urn:openhbx:terms:v1:address_type#mailing')]/../cv:address_line_2",
          "Mailing Address City" =>
            "cv:individual/cv:person/cv:addresses/cv:address/cv:type[contains(text(),'urn:openhbx:terms:v1:address_type#mailing')]/../cv:location_city_name",
          "Mailing Address State" =>
            "cv:individual/cv:person/cv:addresses/cv:address/cv:type[contains(text(),'urn:openhbx:terms:v1:address_type#mailing')]/../cv:location_state_code",
          "Mailing Address Zip" =>
            "cv:individual/cv:person/cv:addresses/cv:address/cv:type[contains(text(),'urn:openhbx:terms:v1:address_type#mailing')]/../cv:postal_code",
          "Temporarily Out of State" => ".//cv:is_temp_out_of_state",
          "Citizen Status" => ".//cv:citizen_status",
          "Is Incarcerated" => ".//cv:person_demographics/cv:is_incarcerated"
        }.freeze

        XML_NS = {
          "cv" => "http://openhbx.org/api/terms/1.0"
        }.freeze

        def initialize(application)
          @financial_assistance_application = application
          @payload = @financial_assistance_application.eligibility_request_payload
        end

        def field_sets
          extract_from_xml
        end

        # rubocop:disable Style/EmptyLiteral
        def extract_from_xml
          doc = Nokogiri::XML(@payload)
          result_fields = Array.new
          doc.xpath("//cv:assistance_tax_household_member/cv:individual/cv:id/cv:id", XML_NS).each do |node|
            assistance_tax_household_member = node.parent.parent.parent
            assistance_tax_household = assistance_tax_household_member.parent.parent
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
            primary_member_id = assistance_tax_household.at_xpath("cv:primary_applicant_id/cv:id", XML_NS).content
            member_id = node.content
            fields["Primary Member ID"] = primary_member_id
            fields["Member ID"] = member_id
            FIELD_MAPPINGS.each_pair do |k,v|
              fields[k] = get_node_value(
                assistance_tax_household_member,
                v
              )
            end
            fields["Relationship"] = resolve_relationship(assistance_tax_household_member, primary_member_id, member_id)
            fields["Indian Tribe Member"] = resolve_indian_tribe_member(assistance_tax_household_member)
            fields["Is Homeless"] = resolve_is_homeless(assistance_tax_household_member)
            result_fields << fields
          end
          result_fields
        end
        # rubocop:enable Style/EmptyLiteral

        def get_node_value(assistance_tax_household_member_node, expression)
          found_node = assistance_tax_household_member_node.at_xpath(expression, XML_NS)
          found_node ? found_node.content : nil
        end

        # rubocop:disable Style/YodaCondition
        def resolve_is_homeless(assistance_tax_household_member)
          addy1 = assistance_tax_household_member.at_xpath(
            "cv:individual/cv:person/cv:addresses/cv:address/cv:type[contains(text(),'urn:openhbx:terms:v1:address_type#home')]/../cv:address_line_1",
            XML_NS
          )
          addy2 = assistance_tax_household_member.at_xpath(
            "cv:individual/cv:person/cv:addresses/cv:address/cv:type[contains(text(),'urn:openhbx:terms:v1:address_type#home')]/../cv:address_line_2",
            XML_NS
          )
          return false if addy1.blank?
          return false if addy2.blank?
          return false if addy1.content.blank?
          return false if addy2.content.blank?
          ("homeless" == addy1.content.strip.downcase) &&
            ("homelessness" == addy2.content.strip.downcase)
        end
        # rubocop:enable Style/YodaCondition

        def resolve_indian_tribe_member(assistance_tax_household_member)
          node = assistance_tax_household_member.at_xpath(".//cv:citizen_status", XML_NS)
          return false unless node
          node.content == "urn:openhbx:terms:v1:citizen_status#indian_tribe_member"
        end

        def resolve_relationship(assistance_tax_household_member_node, primary_member_id, member_id)
          return "self" if member_id == primary_member_id
          found_node = assistance_tax_household_member_node.at_xpath(
            ".//cv:person_relationships/cv:person_relationship/cv:object_individual/cv:id[contains(text(), '#{primary_member_id}')]/../../cv:subject_individual/cv:id[contains(text(), '#{member_id}')]/../../cv:relationship_uri",
            XML_NS
          )
          found_node ? found_node.content.split("#").last : nil
        end
      end
    end
  end
end
