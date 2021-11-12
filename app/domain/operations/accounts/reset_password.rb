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
        reset_password(values.to_h)
      end


      private

      def validate(params)
        AcaEntities::Accounts::Contracts::KeycloakUserRepresentationContract.new
                                                                            .call(params[:account])
      end

      def reset_password(values)
        Keycloak.proc_cookie_token = lambda {
          Keycloak::Client.get_token_by_client_credentials
        }

        result =
          Keycloak::Admin.reset_password(
            values[:id],
            values[:credentials][0]
          )

        Success(result)
      rescue RestClient::BadRequest => e
        if e.http_body
          Failure(JSON.parse(e.http_body).deep_symbolize_keys)
        else
          Failure(e)
        end
      rescue StandardError => e
        Failure(e)
      end
    end
  end
end
