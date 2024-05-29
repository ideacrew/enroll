# frozen_string_literal: true

module Validators
  module HbxEnrollments
    class FindContract < ::Dry::Validation::Contract

      include RegexUtil

      params do
        optional(:hbx_id).filled do
          str? & size?(1..15) & format?(NUMBERS_ONLY_REGEX)
        end

        optional(:id).filled do
          str? & size?(24) & format?(HEXADECIMAL_ONLY_REGEX)
        end

        optional(:external_id).filled do
          # TODO: verify the format of external_id and update the contract accordingly.
          str? & format?(NUMBERS_AND_LETTERS_ONLY_REGEX)
        end
      end
    end
  end
end
