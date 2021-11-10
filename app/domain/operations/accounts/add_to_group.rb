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

        add_to_group(group_id, params[:user_id])
      end

      private

      def find_group_id(group_name)
        # rubocop:disable Style/MultilineBlockChain
        Try() do
          Keycloak.proc_cookie_token = lambda {
            Keycloak::Client.get_token_by_client_credentials
          }
          Keycloak::Admin.get_groups
        end
          .to_result
          .bind do |response|
            response = JSON.parse(response)
            matching_group =
              response.find { |group| group['name'] == group_name }
            if matching_group
              Success(matching_group['id'])
            else
              Failure('Group not found')
            end
          end
        # rubocop:enable Style/MultilineBlockChain
      end

      def add_to_group(group_id, user_id)
        Try() { Keycloak::Admin.add_user_to_group(user_id, group_id) }
          .to_result
          .bind { |response| Success(response) }
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
