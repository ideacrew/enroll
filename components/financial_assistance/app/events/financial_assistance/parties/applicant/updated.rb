# frozen_string_literal: true
module FinancialAssistance
  module Parties
    module Applicant
      class Updated < EventSource::Event
        publisher_key 'financial_assistance.parties.applicant_publisher'
        attribute_keys :applicant_attributes, :family_id

      end
    end
  end
end
