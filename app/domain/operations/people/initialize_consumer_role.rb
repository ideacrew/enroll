# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module People
    class InitializeConsumerRole
      include Dry::Monads[:result, :do]

      def call(applicant_params)
        contract = yield validate(applicant_params)
        result = yield create_entity(contract)

        Success(result)
      end

      private

      def validate(params)
        contract = Validators::Families::ConsumerRoleContract.new.call(params)

        if contract.success?
          Success(contract)
        else
          Failure(contract)
        end
      end

      def create_entity(contract)
        entity = Entities::ConsumerRole.new(contract.to_h)

        Success(entity)
      end
    end
  end
end