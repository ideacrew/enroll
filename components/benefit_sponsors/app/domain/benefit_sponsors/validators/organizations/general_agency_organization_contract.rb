# frozen_string_literal: true

module BenefitSponsors
  module Validators
    module Organizations
      # General Agency Organization Contract is to validate submitted params while persisting General Agency Organization
      class GeneralAgencyOrganizationContract < Dry::Validation::Contract

        params do
          required(:entity_kind).filled(:string)
          required(:legal_name).filled(:string)
          optional(:dba).maybe(:string)
          required(:fein).filled(:string)
          required(:profile).array(:hash)
        end

        rule(:profile).each do
          if key? && value
            result = BenefitSponsors::Validators::Profiles::AgencyProfileContract.new.call(value)
            key.failure(text: "invalid profile", error: result.errors.to_h) if result&.failure?
          end
        end
      end
    end
  end
end
