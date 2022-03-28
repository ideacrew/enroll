# frozen_string_literal: true

module ClientReporting
  module Dc
    module FinancialAssistanceAuditReport
      XML_NS = {
        "cv" => "http://openhbx.org/api/terms/1.0"
      }.freeze

      # Extracts data fields from the response payload.
      class ResponsePayloadExtractor
        def initialize(application)
          @financial_assistance_application = application
          @payload = @financial_assistance_application.eligibility_response_payload
        end

        def field_sets
          extract_from_xml
        end

        # rubocop:disable Style/EmptyLiteral
        def extract_from_xml
          doc = Nokogiri::XML(@payload)
          result_fields = Array.new
          doc.xpath("//cv:person/cv:id/cv:id", XML_NS).each do |node|
            fields = Hash.new
            fields["Member ID"] = node.content
            family_member_node = node.parent.parent.parent
            fields["Is Insurance Assistance Eligible"] = get_node_value(
              family_member_node,
              "cv:is_insurance_assistance_eligible"
            )
            fields["Is Medicaid CHIP Eligible"] = get_node_value(
              family_member_node,
              "cv:is_medicaid_chip_eligible"
            )
            fields["Is Without Assistance"] = get_node_value(
              family_member_node,
              "cv:is_without_assistance"
            )
            fields["Is Totally Ineligible"] = get_node_value(
              family_member_node,
              "cv:is_totally_ineligible"
            )
            result_fields << fields
          end
          result_fields
        end
        # rubocop:enable Style/EmptyLiteral

        def get_node_value(family_member_node, expression)
          found_node = family_member_node.at_xpath(expression, XML_NS)
          found_node ? found_node.content : nil
        end
      end
    end
  end
end