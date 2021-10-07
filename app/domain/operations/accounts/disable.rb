# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Accounts
    # Disable a Keycloak Account
    class Disable
      include Dry::Monads[:result, :do, :try]

      # @param [Hash] opts the parameters to disable a {AcaEntities::Accounts::Account}
      # @option opts [String] :id optional
      # @option opts [String] :login optional
      # @option opts [Hash] :cookies optional
      # @return [Dry::Monad] result
      def call(params)
        values = yield validate(params)
        _token_proc = yield cookie_token(values)
        result = yield disable(values.to_h)

        Success(result)
      end

      private

      def validate(params)
        if params.key?(:login) || params.key?(:id)
          Success(params)
        else
          Failure('params must include :id or :login')
        end
      end

      def cookie_token(values)
        cookies =
          values[:cookies] || {
            keycloak_token: Keycloak::Client.get_token_by_client_credentials
          }

        if cookies.nil?
          Failure('unable to set proc_cookie_token')
        else
          Success(
            Keycloak.proc_cookie_token = -> { cookies[:keycloak_token] }
          )
        end
      end

      # rubocop:disable Style/MultilineBlockChain
      def disable(values)
        Try() do
          if values[:id]
            Keycloak::Internal.disable_user(values[:id])
          else
            Keycloak::Internal.disable_user_by_login(values[:login])
          end
        end.to_result.bind { |response| Success(response) }
      end
      # rubocop:enable Style/MultilineBlockChain
    end
  end
end
