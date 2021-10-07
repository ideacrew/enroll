# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Accounts
    # Create a new Keycloak Account
    class Create
      include Dry::Monads[:result, :do, :try]

      # @param [Hash] acct {AcaEntities::Accounts::Account}-related parameters
      # @option acct [String] :id optional
      # @option acct [String] :username required
      # @option acct [String] :password optional
      # @option acct [String] :email optional
      # @option acct [String] :first_name optional
      # @option acct [String] :last_name optional
      # @option acct [Boolean] :enabled optional
      # @option acct [Boolean] :email_verified optional
      # @option acct [Hash] :attributes optional
      # @option acct [Array<String>] :groups optional
      # @option acct [Hash] :access optional
      # @option acct [Integer] :not_before optional
      # @option acct [Time] :created_at optional
      # @param [Hash] opts Cookie-related parameters
      # @option opts [Hash] :cookie optional
      # @return [Dry::Monad] result
      def call(params)
        values = yield validate(params)
        _token_proc = yield cookie_token(values)
        keycloak_attrs = yield create(values)
        account_attrs = yield map_attributes(keycloak_attrs)

        Success(account_attrs)
      end

      private

      def validate(params)
        AcaEntities::Accounts::Contracts::AccountContract.new.call(
          params[:account]
        )
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

      # rubocop:disable Style/MultilineBlockChain
      def create(values)
        Try() do
          after_insert =
            lambda do |user, new_user|
              return { 'user' => user, 'new_user' => new_user }
            end

          args = values.to_h
          Keycloak::Internal.create_simple_user(
            args[:username] || args[:email],
            args[:password],
            args[:email],
            args[:first_name],
            args[:last_name],
            [],
            ['Public'],
            after_insert
          )
        end.to_result.bind do |response|
          response['new_user'] ? Success(response) : Failure(response)
        end
      end
      # rubocop:enable Style/MultilineBlockChain

      def map_attributes(keycloak_attrs)
        account_attrs = {
          id: keycloak_attrs['user']['id'],
          username: keycloak_attrs['user']['username'],
          enabled: keycloak_attrs['user']['enabled'],
          totp: keycloak_attrs['user']['totp'],
          email: keycloak_attrs['user']['email'],
          email_verified: keycloak_attrs['user']['emailVerified'],
          access: keycloak_attrs['user']['access'],
          first_name: keycloak_attrs['user']['firstName'],
          last_name: keycloak_attrs['user']['lastName'],
          attributes: keycloak_attrs['user']['attributes'] || {},
          groups: keycloak_attrs['user']['groups'] || [],
          not_before: keycloak_attrs['user']['notBefore'],
          created_at: epoch_to_time(keycloak_attrs['user']['createdTimestamp'])
        }

        Success(account_attrs)
      end

      def epoch_to_time(value)
        Time.at(value / 1000)
      end
    end
  end
end
