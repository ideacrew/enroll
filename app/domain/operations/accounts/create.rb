# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Accounts
    # Create a new Keycloak Account
    # a {Sections::SectionItem}
    class Create
      include Dry::Monads[:result, :do, :try]
      include ActionController::Cookies

      # @param [Hash] opts the parameters wrapped in account: hash to create a
      # {AcaEntities::Accounts::Account}
      # @option opts [String] :username optional
      # @option opts [String] :password required
      # @option opts [String] :email required
      # @option opts [String] :first_name required
      # @option opts [String] :last_name required
      # @option opts [Hash] :cookies optional
      # @return [Dry::Monad] result
      def call(params)
        values = yield validate(params)
        _token_proc = yield proc_cookie_token(values)
        new_account = yield create(values.to_h)

        Success(new_account)
      end

      private

      def validate(params)
        AcaEntities::Accounts::Contracts::AccountContract.new.call(
          params[:account]
        )
      end

      def proc_cookie_token(values)
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

          Keycloak::Internal.create_simple_user(
            values[:username] || values[:email],
            values[:password],
            values[:email],
            values[:first_name],
            values[:last_name],
            [],
            ['Public'],
            after_insert
          )
        end.to_result.bind do |response|
          response['new_user'] ? Success(response) : Failure(response)
        end
      end
      # rubocop:enable Style/MultilineBlockChain
    end
  end
end
