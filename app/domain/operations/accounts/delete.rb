# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Accounts
    # Create a new Keycloak Account
    class Delete
      include Dry::Monads[:result, :do, :try]

      # @param [Hash] opts the parameters to delete a {AcaEntities::Accounts::Account}
      # @option opts [String] :id required
      # @option opts [String] :login optional
      # @option opts [Hash] :cookies optional
      # @return [Dry::Monad] result
      def call(params)
        values = yield validate(params)
        _token_proc = yield cookie_token(values)
        result = yield delete(values.to_h)

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
          Success(Keycloak.proc_cookie_token = -> { cookies[:keycloak_token] })
        end
      end

      # rubocop:disable Layout/MultilineMethodCallIndentation
      def delete(values)
        Try() do
          if values[:id]
            Keycloak::Admin.delete_user(values[:id])
          else
            Keycloak::Internal.delete_user_by_login(values[:login])
          end
        end.to_result.bind do |response|
          response ? Success(true) : Failure(false)
        end
      end
      # rubocop:enable Layout/MultilineMethodCallIndentation
    end
  end
end
