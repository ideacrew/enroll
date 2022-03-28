# frozen_string_literal: true

module ClientReporting
  module Dc
    module FinancialAssistanceAuditReport
      # Encapsulates queries for data used to populate the report in a given
      # fiscal year.
      class Query
        def initialize(params = {})
          @query_parameters = params
          @application_ids = []
        end

        def prepare
          @application_ids = ::FinancialAssistance::Application.where(
            {
              eligibility_response_payload: {
                "$ne" => nil
              }
            }.merge(@query_parameters)
          ).pluck(:_id)
        end

        # rubocop:disable Style/ExplicitBlockArgument
        def each
          @application_ids.each_slice(250) do |ids|
            records = ::FinancialAssistance::Application.where(
              {
                _id: {"$in" => ids}
              }
            )
            records.each do |app|
              yield app
            end
          end
        end
        # rubocop:enable Style/ExplicitBlockArgument
      end
    end
  end
end