# frozen_string_literal: true

require "dry/monads"
require "dry/monads/do"

module Operations
  module Eligible
    # Operation to support eligibility creation
    class BuildGrant
      include Dry::Monads[:do, :result]

      # @param [Hash] opts Options to build eligibility
      # @option opts [<Symbol>]   :grant_key required
      # @option opts [<String>]   :grant_value required
      # @return [Dry::Monad] result
      def call(params)
        values = yield validate(params)
        grant_options = yield build(values)

        Success(grant_options)
      end

      private

      def validate(params)
        errors = []
        errors << "grant key missing" unless params[:grant_key]
        errors << "grant value missing" unless params[:grant_value]

        errors.empty? ? Success(params) : Failure(errors)
      end

      def build(values)
        grant_key = values[:grant_key]
        grant_value = values[:grant_value]

        Success(
          {
            title: grant_key.to_s.titleize,
            key: grant_key.to_sym,
            value: {
              title: grant_key.to_s.titleize,
              key: grant_key.to_sym,
              item: grant_value
            }
          }
        )
      end
    end
  end
end