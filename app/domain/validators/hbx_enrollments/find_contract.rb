# frozen_string_literal: true

module Validators
  module HbxEnrollments
    # The FindContract class is responsible for validating input values for datatype, size, and format.
    #
    # @example
    #   contract = Validators::HbxEnrollments::FindContract.new
    #   contract.call(hbx_id: '123456789012345', id: '4d7a457f4d345b7a8a9b0c1d', external_id: '123abc')
    #
    # @see Dry::Validation::Contract
    class FindContract < ::Dry::Validation::Contract
      include RegexUtil

      # Defines the validation rules for the parameters.
      #
      # @return [Dry::Schema::Params]
      params do
        # The hbx_id parameter must be a string of 1 to 15 digits.
        #
        # @option params [String] :hbx_id a string of 1 to 15 digits
        optional(:hbx_id).filled do
          str? & size?(1..15) & format?(NUMBERS_ONLY_REGEX)
        end

        # The id parameter must be a 24-character hexadecimal string.
        #
        # @option params [String] :id a 24-character hexadecimal string
        optional(:id).filled do
          str? & size?(24) & format?(HEXADECIMAL_ONLY_REGEX)
        end

        # The external_id parameter must be a string of numbers and letters.
        # TODO: verify the format of external_id and update the contract accordingly.
        #
        # @option params [String] :external_id a string of numbers and letters
        optional(:external_id).filled do
          str? & format?(NUMBERS_AND_LETTERS_ONLY_REGEX)
        end
      end
    end
  end
end
