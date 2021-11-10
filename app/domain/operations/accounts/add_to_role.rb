# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Accounts
    # Find Keycloak Account(s) that match criteria
    class AddToRole
      include Dry::Monads[:result, :do, :try]

      # @param [Hash] acct {AcaEntities::Accounts::Account}-related parameters
      # @option acct [Symbol] :scope_name required
      # @option opts [Hash] :criterion optional
      # @option opts [Integer] :page_size optional
      # @option opts [Integer] :page_number optional
      # @return [Dry::Monad] result
      def call(params)
        roles = yield map_roles(params[:roles])

        add_roles(roles, params[:id])
      end

      private

      def map_roles(roles)
        roles.map! do |role|
          find_role(role)
        end

        Rails.logger.warn(roles.select(&:failure?).map(&:failure).join("\n")) if roles.any?(&:failure?)
        Success(roles.select(&:success?).map(&:success))
      end

      def find_role(role_name)
        # rubocop:disable Style/MultilineBlockChain
        Try() do
          Keycloak.proc_cookie_token = lambda {
            Keycloak::Client.get_token_by_client_credentials
          }
          Keycloak::Admin.get_roles
        end
          .to_result
          .bind do |response|
            response = JSON.parse(response)
            matching_role =
              response.find { |role| role['name'] == role_name }
            if matching_role
              Success(matching_role)
            else
              Failure("Role not found for #{role_name}")
            end
          end
        # rubocop:enable Style/MultilineBlockChain
      end

      def add_roles(roles, id)
        Try() { Keycloak::Admin.add_user_to_roles(id, roles) }
          .to_result
          .bind { |response| Success(response) }
      end
    end
  end
end
