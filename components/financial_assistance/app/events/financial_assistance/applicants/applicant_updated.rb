# frozen_string_literal: true
module FinancialAssistance
  module Applicants
    class ApplicantUpdated < EventSource::Event
      publisher_key 'financial_assistance.applicants_publisher'
      
      # attribute_keys :applicant_attributes, :family_id
    end
  end
end
