# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Accounts
    # Find Keycloak Account(s) that match criteria
    class GetUser
      include Dry::Monads[:result, :do, :try]

      # @param [Hash] acct {AcaEntities::Accounts::Account}-related parameters
      # @option acct [Symbol] :scope_name required
      # @option opts [Hash] :criterion optional
      # @option opts [Integer] :page_size optional
      # @option opts [Integer] :page_number optional
      # @return [Dry::Monad] result
      def call(id)
        get_user(id)
      end

      def get_user(id)
        Keycloak.proc_cookie_token = lambda {
          Keycloak::Client.get_token_by_client_credentials
        }
        response = Keycloak::Admin.get_user(id)
        Success(JSON.parse(response))
      rescue RestClient::NotFound
        Failure("User not found for #{id}")
      rescue StandardError => e
        Failure("Error retreiving #{id}: #{e.inspect}")
      end
    end
  end
end