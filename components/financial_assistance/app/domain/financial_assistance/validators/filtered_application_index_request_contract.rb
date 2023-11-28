# frozen_string_literal: true

module FinancialAssistance
  module Validators
    # Validates parameters used to query applications using filter criteria.
    class FilteredApplicationIndexRequestContract < Dry::Validation::Contract
      params do
        required(:family_id).filled(Types::Bson)
        optional(:filter_year).maybe(:integer)
      end
    end
  end
end