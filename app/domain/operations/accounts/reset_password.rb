# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Accounts
    # Change an {AcaEntities::Accounts::Account} password to the passed credentials
    class ResetPassword
      include Dry::Monads[:result, :do, :try]

      # @param [Hash] opts the Keycloak Account including credential parameters to change an Account password
      # @option opts [AcaEntities::Accounts::Contracts::KeycloakAccountRepresentationContract] :account
      # @option opts [ActiondDspatch::Cookies] :token (optional)
      # @return [Dry::Monad::Success] if password reset succeeds
      # @return [Dry::Monad::Failure] if password reset fails
      # @example ResetPassword Operation call:
      # Operations::Accounts::ResetPassword.new.call(
      #   account: {
      #     id: '6304e375-c5f6-45c4-bd9c-da75b01d19f4',
      #     credentials: [{
      #       type: 'password',
      #       temporary: false,
      #       value: '$3cr3tP@55w0rd'
      #     }]
      #   }
      # )
      def call(params)
        values = yield validate(params)
        _token_proc = yield cookie_token(values)
        result = yield reset_password(values.to_h)

        Success(result)
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

      def reset_password(values)
        result =
          Keycloak::Admin.reset_password(
            values[:id],
            values[:credentials][0]
          )

        Success(result)
      end
    end
  end
end
