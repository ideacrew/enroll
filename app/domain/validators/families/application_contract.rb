# frozen_string_literal: true

module Validators
  module Families
    class ApplicationContract < Dry::Validation::Contract

      params do
        required(:family_id).filled(Types::Bson)
        required(:assistance_year).filled(:integer)
        optional(:years_to_renew).maybe(:integer)
        optional(:renewal_consent_through_year).maybe(:integer)
        required(:benchmark_product_id).filled(Types::Bson)
        optional(:is_ridp_verified).maybe(:bool)
        required(:applicants).array(:hash)
      end

      rule(:family_id) do
        if key? && value
          result = Operations::Families::Find.new.call(id: value)
          key.failure(text: 'invalid family_id', error: result.errors.to_h) if result&.failure?
        end
      end

      rule(:applicants).each do  |key, value|
        if key? && value
          if value.is_a?(Hash)
            result = ::FinancialAssistance::Validators::ApplicantContract.new.call(value)
            key.failure(text: "invalid applicant", error: result.errors.to_h) if result&.failure?
          else
            key.failure(text: "invalid applicant. Expected a hash.")
          end
        end
      end
    end
  end
end
