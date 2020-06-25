# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module SecureMessages
    class SecureMessage
      send(:include, Dry::Monads[:result, :do, :try])

      def call(params:)
        validate_params = yield validate_params(params)

        Success(validate_params)
      end

      private

      def validate_params(params)
        result = ::Validators::SecureMessages::SecureMessageContract.new.call(params)

        result.success? ? Success(result.to_h) : Failure(result.errors.to_h)
      end
    end
  end
end
