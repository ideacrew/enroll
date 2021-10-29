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
        new_user = yield create_account(values.to_h)

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
          Operations::Accounts::Create.new.call(account: values)
        end.to_result.bind do |account|
          user = User.new(
            {
              oim_id: values[:username],
              roles: values[:roles],
              password: values[:password]
            }
          )

          return Failure(account: account, user: user) unless account.success?
          account_attrs = account.success

          user.account_id = account_attrs[:user][:id]
          if user.valid?
            user.save!
            Success(
              {
                account: account.success,
                user: user
              }
            )
          else
            Operations::Accounts::Delete.new.call(id: account_attrs[:user][:id])
            Failure(
              message: "Error creating User: #{user}\n for account: #{account_attrs}",
              user: user
            )
          end
        end
      end
      # rubocop:enable Style/MultilineBlockChain
    end
  end
end
