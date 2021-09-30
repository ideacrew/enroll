# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Accounts
    # Change the password for a {AcaEntities::Accounts::Account}
    class ForgotPassword
      include Dry::Monads[:result, :do, :try]

      # @param [Hash] opts the parameters to change an Account password
      # @option opts [String] :username required
      # @return [Dry::Monad] result
      def call(params)
        values = yield validate(params)
        _token_proc = yield proc_cookie_token(values)
        result = yield reset_password(values.to_h)

        Success(result)
      end

      private

      def validate(params)
        if params.keys.include? :username
          Success(params)
        else
          Failure('params must include :username')
        end
      end

      def proc_cookie_token(values)
        cookies =
          values[:cookies] || {
            keycloak_token: Keycloak::Client.get_token_by_client_credentials
          }

        if cookies.nil?
          Failure('unable to set proc_cookie_token')
        else
          Success(Keycloak.proc_cookie_token = -> { cookies[:keycloak_token] })
        end
      end

      # rubocop:disable Style/MultilineBlockChain
      def reset_password(values)
        Try() do
          Keycloak.proc_cookie_token = -> { cookies.permanent[:keycloak_token] }

          Keycloak::Internal.forgot_password(values[:username])
        end.to_result.bind { |response| Success(response) }
      end
      # rubocop:enable Style/MultilineBlockChain
    end
  end
end
