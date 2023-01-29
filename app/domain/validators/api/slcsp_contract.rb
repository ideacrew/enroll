# frozen_string_literal: true

module Validators
  module Api
    # this is the contract for the Slcp calculator, this will arrive via an api call from an angular app
    class SlcspContract < ::Dry::Validation::Contract

      params do
        required(:taxYear).filled(:integer)
        optional(:state).value(:string)
        required(:members).array(:hash) do
          optional(:primaryMember).value(:bool)
          required(:relationship).value(:string)
          required(:name).value(:string)
          required(:dob).hash do
            required(:month).filled(:integer)
            required(:day).filled(:integer)
            required(:year).filled(:integer)
          end
          required(:residences).array(:hash) do
            required(:county).hash do
              required(:zipcode).filled(:string)
              required(:name).filled(:string)
              required(:fips).filled(:string)
              required(:state).filled(:string)
            end
            required(:months).hash do
              required(:jan).filled(:bool)
              required(:feb).filled(:bool)
              required(:mar).filled(:bool)
              required(:apr).filled(:bool)
              required(:may).filled(:bool)
              required(:jun).filled(:bool)
              required(:jul).filled(:bool)
              required(:aug).filled(:bool)
              required(:sep).filled(:bool)
              required(:oct).filled(:bool)
              required(:nov).filled(:bool)
              required(:dec).filled(:bool)
            end
          end
          required(:coverage).hash do
            required(:jan).filled(:bool)
            required(:feb).filled(:bool)
            required(:mar).filled(:bool)
            required(:apr).filled(:bool)
            required(:may).filled(:bool)
            required(:jun).filled(:bool)
            required(:jul).filled(:bool)
            required(:aug).filled(:bool)
            required(:sep).filled(:bool)
            required(:oct).filled(:bool)
            required(:nov).filled(:bool)
            required(:dec).filled(:bool)
          end
        end
      end
    end
  end
end
