# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Accounts
    # Create a new Keycloak Account
    # a {Sections::SectionItem}
    class Delete
      include Dry::Monads[:result, :do, :try]

      # @param [Hash] opts the parameters to delete a {AcaEntities::Accounts::Account}
      # @option opts [String] :id required
      # @option opts [Hash] :cookies optional
      # @return [Dry::Monad] result
      def call(params)
        values = yield validate(params)
        _token_proc = yield proc_cookie_token(values)
        result = yield delete(values.to_h)

        Success(result)
      end

      private

      def validate(params)
        params.key?(:id) ? Success(params) : Failure('params must include :id')
      end

      def proc_cookie_token(values)
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

      # rubocop:disable Layout/MultilineMethodCallIndentation
      def delete(values)
        Try() { Keycloak::Admin.delete_user(values[:id]) }.to_result
          .bind do |response|
          if response
            Success("account_id: #{values[:id]} deleted")
          else
            Failure("error deleting account_id: #{values[:id]}")
          end
        end
      end
      # rubocop:enable Layout/MultilineMethodCallIndentation
    end
  end
end
