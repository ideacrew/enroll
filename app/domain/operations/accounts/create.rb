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

      def create(values)
        Try() do
          after_insert =
            lambda do |user, new_user|
              return { user: user, new_user: new_user }
            end

          args = values.to_h
          Keycloak::Internal.create_simple_user(
            args[:username] || args[:email],
            args[:password],
            args[:email],
            args[:first_name],
            args[:last_name],
            args[:realm_roles] || [], # realm roles
            [], # client roles
            after_insert
          )
        end.to_result
      end

      def map_attributes(keycloak_attributes)
        user_attributes =
          Operations::Accounts::MapAttributes.new.call(
            keycloak_attributes[:user]
          )

        if user_attributes.success?
          keycloak_attributes[:user] = user_attributes.success
          if keycloak_attributes[:new_user]
            Success(keycloak_attributes)
          else
            Failure(keycloak_attributes)
          end
        else
          user_attributes
        end
      end
    end
  end
end
