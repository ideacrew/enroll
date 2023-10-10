# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module People
    class InitializeConsumerRole
      include Dry::Monads[:result, :do]

      def call(params)
        contract = yield validate(params)
        result = yield create_entity(contract)

        Success(result)
      end

      private

      def sanitize_params(params)
        params[:is_applicant] = params.delete :is_primary_applicant if params[:is_primary_applicant]
        params
      end

      def validate(params)
        contract = Validators::Families::ConsumerRoleContract.new.call(sanitize_params(params))

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