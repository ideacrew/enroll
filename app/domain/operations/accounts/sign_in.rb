# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Accounts
  # Add a new Account
  # a {Sections::SectionItem}
  class SignIn
    include Dry::Monads[:result, :do, :try]

    # @param [Hash] opts the parameters to render a SectionItem
    # @option opts [String] :username required
    # @option opts [String] :password required
    # @return [Dry::Monad] result
    # @return [Dry::Monad::Failure(Array<Liquid::UndefinedVariable>)] if parsing errors occur
    def call(params)
      values = yield validate(params)
      tokens = yield sign_in(values)

      Success(tokens)
    end

    private

    def validate(params)
      if params.keys.include? %i[email password]

      else

      end
      Accounts::AccountContract.new.call(params)
    end

    def sign_in(values)
      Keycloak::Client.get_token values[:email], values[:password]

      Keycloak::Internal.create_simple_user(
        params[:email],
        params[:password],
        params[:email],
        params[:first_name],
        params[:last_name],
        [],
        ['Public'],
        after_insert
      )
    end
  end
end
