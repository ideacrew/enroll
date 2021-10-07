# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Accounts
    # Find Keycloak Account(s) that match criteria
    class Find
      include Dry::Monads[:result, :do, :try]

      # @param [Hash] acct {AcaEntities::Accounts::Account}-related parameters
      # @option acct [Symbol] :scope_name required
      # @option opts [Hash] :options optional
      # @return [Dry::Monad] result
      def call(params)
        values = yield validate(params)
        templates = yield search(values)

        Success(templates)
      end

      private

      def validate(params)
        valid_scopes = %i[by_username by_email]
        if params.keys.include?(:scope_name) &&
             valid_scopes.include?(params[:scope_name])
          Success(params)
        else
          Failure(
            'params must include :scope_name key and valid scope: #{valid_scopes}'
          )
        end
      end

      def search(values)
        Try() do
          scope_name = values[:scope_name]
          unless values[:options].present?
            return Failure('options key required')
          end

          case scope_name
          when :by_username, :by_email
            Keycloak::Internal.get_user_info(values[:options], true)
          end
        end.bind { |result| result ? Success(result) : Failure(result) }
      end
    end
  end
end

# Enable/Disable Account
# Forgot Password - Password reset via email
# Change Password - Password reset where CSR picks password
# Create Account
# Delete Account
# See Login History

# { scope_name: :by_username, options: { username: 'batman' } }
# :by_email
