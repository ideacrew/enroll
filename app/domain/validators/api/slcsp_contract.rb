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
            optional(:absent).value(:bool)
            optional(:county).hash do
              optional(:zipcode).value(:string)
              optional(:name).value(:string)
              optional(:fips).value(:string)
              optional(:state).value(:string)
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

      rule(:residences) do
        if values[:members].present?
          values[:members].each_with_index do |member, member_index|
            member[:residences].each_with_index do |residence, residence_index|
              next if residence[:absent]
              next if valid_county?(residence[:county])
              key(
                [:member, member_index, :residences, residence_index, :county]
              ).failure(text: 'please provide valid county information')
            end
          end
        end
      end

      def valid_county?(county)
        county.present? && county.is_a?(Hash) && county[:name].present? && county[:state].present? && county[:zipcode].present?
      end

    end
  end
end
