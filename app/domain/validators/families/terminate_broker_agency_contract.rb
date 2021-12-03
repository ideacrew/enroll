# frozen_string_literal: true

module Validators
  module Families
    # Validator that validates broker agency term params.
    class TerminateBrokerAgencyContract < Dry::Validation::Contract

      params do
        required(:family_id).filled(Types::Bson)
        required(:broker_account_id).filled(Types::Bson)
        required(:terminate_date).filled(:date)
      end

      rule(:broker_account_id) do
        if key? && value
          result = Operations::Families::FindBrokerAgencyAccount.new.call({family_id: values[:family_id], broker_account_id: values[:broker_account_id]})
          key.failure(text: 'invalid broker_account_id', error: result.failure) if result&.failure?
        end
      end
    end
  end
end
