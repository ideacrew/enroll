# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Accounts
    # Find Keycloak Account(s) that match criteria
    class Find
      include Dry::Monads[:result, :do, :try]
      VALID_SCOPES = %i[
        all
        by_username
        by_email
        by_first_name
        by_last_name
        by_any
      ].freeze

      # @param [Hash] acct {AcaEntities::Accounts::Account}-related parameters
      # @option acct [Symbol] :scope_name required
      # @option opts [Hash] :criterion optional
      # @option opts [Integer] :page_size optional
      # @option opts [Integer] :page_number optional
      # @return [Dry::Monad] result
      def call(params)
        values = yield validate(params)
        _token_proc = yield cookie_token(values)
        users = yield search(values)

        Success(users)
      end

      private

      def validate(params)
        # rubocop:disable Layout/MultilineOperationIndentation
        if params[:scope_name].present? &&
             VALID_SCOPES.include?(params[:scope_name])
          Success(params)
          # rubocop:enable Layout/MultilineOperationIndentation
        else
          Failure(
            "params must include :scope_name key and valid scope: #{valid_scopes}"
          )
        end
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

      def search(values)
        require 'pry'
        binding.pry

        # rubocop:disable Style/MultilineBlockChain
        Try() do
          query_params = search_scope(values).merge(pagiation(values))
          Keycloak::Admin.get_users(query_params)
        end.bind { |result| result ? Success(result) : Failure(result) }
        # rubocop:enable Style/MultilineBlockChain
      end

      def search_scope(params)
        case params[:scope_name]
        when :all
          {}
        when :by_username
          { username: params[:criterion] }
        when :by_first_name
          { first_name: params[:criterion] }
        when :by_last_name
          { last_name: params[:criterion] }
        when :by_email
          { email: params[:criterion] }
        when :by_any
          { search: params[:criterion] }
        end
      end

      def pagiation(values)
        { first: values[:page_number] || 0, max: values[:page_size] || 100 }
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
