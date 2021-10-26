# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Accounts
    # Update values on an existing Keycloak User account
    class Update
      include Dry::Monads[:result, :do, :try]

      # @param [Hash] opts the Keycloak Account including credential parameters to change an Account password
      # @option opts [AcaEntities::Accounts::Contracts::KeycloakAccountRepresentationContract] :account
      # @option opts [ActiondDspatch::Cookies] :token (optional)
      # @return [Dry::Monad::Success] if update succeeds
      # @return [Dry::Monad::Failure] if update fails
      # @example ResetPassword Operation call:
      # Operations::Accounts::Update.new.call(
      #   account: {
      #     id: '6304e375-c5f6-45c4-bd9c-da75b01d19f4',
      #     username: 'new_username,
      #     email: 'new_email@example.com,
      #   }
      # )
      def call(params)
        values = yield validate(params)
        _token_proc = yield cookie_token(values)
        yield update(values)

        Success(values)
      end

      private

      def validate(params)
        AcaEntities::Accounts::Contracts::KeycloakUserRepresentationContract.new
                                                                            .call(params[:account])
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

      def update(values)
        result =
          Try[RestClient::Conflict] do
            Keycloak::Admin.update_user(
              values.to_h[:id],
              values.to_h.except(:id)
            )
          end.to_result

        return Failure('Username or Email already exists') if result.failure?
        result
      end
    end
  end
end
