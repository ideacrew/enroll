# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Accounts
    # Find Keycloak Account(s) that match criteria
    class AddToGroup
      include Dry::Monads[:result, :do, :try]
      VALID_SCOPES = %i[
        all
        by_username
        by_email
        by_first_name
        by_last_name
        by_any
        count_all
      ].freeze

      # @param [Hash] acct {AcaEntities::Accounts::Account}-related parameters
      # @option acct [Symbol] :scope_name required
      # @option opts [Hash] :criterion optional
      # @option opts [Integer] :page_size optional
      # @option opts [Integer] :page_number optional
      # @return [Dry::Monad] result
      def call(params)
        group_id = yield find_group_id(params[:group])
        yield add_to_group(group_id, params[:user_id])
      end

      private

      def find_group_id(group_name)
        Try() do
          Keycloak.proc_cookie_token = -> { Keycloak::Client.get_token_by_client_credentials }
          Keycloak::Admin.get_groups
        end.to_result.bind do |response|
          response = JSON.parse(response)
          matching_group = response.find do |group|
            group['name'] == group_name
          end
          if matching_group
            Success(matching_group['id'])
          else
            Failure("Group not found")
          end
        end
      end

      def add_to_group(group_id, user_id)
        puts group_id.inspect
        puts user_id.inspect
        Try() do
          Keycloak::Admin.add_user_to_group(user_id, group_id)
        end.to_result.bind do |response|
          Success(response)
        end
      end
    end
  end
end

# Enable/Disable Account
# Forgot Password - Password reset via email
# Reset Password - Password reset where CSR picks password
# See Login History

# { scope_name: :by_username, criterion: { username: 'batman' } }
# :by_email
