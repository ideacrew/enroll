# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Users
    # Create a new User
    class Create
      include Dry::Monads[:result, :do, :try]

      # @param [Hash] opts the parameters wrapped in account: hash to create a
      # {AcaEntities::Accounts::Account}
      # @option opts [String] :id required
      # @option opts [Array<String>] :roles optional
      # @option opts [Array] :Groups optional
      # @return [Dry::Monad] result
      def call(params)
        values = yield validate(params)
        puts values.inspect
        new_user = yield create_account(values)

        Success(new_user)
      end

      private

      def validate(params)
        AcaEntities::Accounts::Contracts::AccountContract.new.call(params[:account])
      end

      # rubocop:disable Style/MultilineBlockChain
      # Create a Keycloak account with an associated {User} record
      def create_account(values)
        Try() do
          Operations::Accounts::Create.new.call(account: values.to_h)
        end.to_result.bind do |account|
          return account unless account.success?
          account_attrs = account.success
          user =
            User.create(
              {
                account_id: account_attrs[:user][:id],
                oim_id: account_attrs[:user][:id],
                roles: values.to_h[:roles],
                password: values.to_h[:password]
              }
            )

          if user.valid?
            Success(
              {
                account: account.success,
                user: user
              }
            )
          else
            Operations::Accounts::Delete.new.call(id: account_attrs[:user][:id])
            Failure(
              "Error creating User: #{user}\n for account: #{account_attrs}"
            )
          end
        end
      end
      # rubocop:enable Style/MultilineBlockChain
    end
  end
end
