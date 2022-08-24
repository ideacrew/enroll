# frozen_string_literal: true

module BenefitSponsors
  module Validators
    class EnrollmentEligibilityContract < Dry::Validation::Contract

      params do
        required(:market_kind).filled(:symbol)
        required(:benefit_sponsorship_id).filled(Types::Bson)
        required(:effective_date).filled(:date)
        required(:benefit_application_kind).filled(:symbol)
        required(:service_areas).array(:hash)
        required(:osse_min_employer_contribution).filled(:bool)
      end
    end
  end
end