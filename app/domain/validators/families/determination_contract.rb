# frozen_string_literal: true

module Validators
  module Families
    class DeterminationContract < Dry::Validation::Contract

      params do
        required(:max_aptc).filled(:hash)
        required(:csr_percent_as_integer).filled(:integer)
        required(:source).filled(:string)
        required(:aptc_csr_annual_household_income).filled(:hash)
        required(:aptc_annual_income_limit).filled(:hash)
        required(:csr_annual_income_limit).filled(:hash)
        required(:determined_at).filled(:date)

        optional(:yearly_expected_contribution).maybe(:hash)

        before(:value_coercer) do |result|
          result_hash = result.to_h
          other_params = {}
          other_params[:determined_at] = result_hash[:determined_at].to_date if result_hash[:determined_at].present?
          result_hash.merge(other_params)
        end
      end
    end
  end
end
