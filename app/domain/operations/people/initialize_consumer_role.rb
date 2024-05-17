# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module People
    # Class for initializing a new consumer role object
    class InitializeConsumerRole
      include Dry::Monads[:do, :result]

      # Initializes a new consumer role object with the given parameters.
      #
      # @param params [Hash] The parameters for initializing the consumer role.
      # @option params [String] :is_applicant Whether the consumer role is for an applicant.
      # @option params [String] :vlp_documents_attributes The attributes for the VLP documents.
      # @return [Dry::Monads::Result] The result of the operation.
      def call(params)
        contract = yield validate(params)
        result = yield create_entity(contract)

        Success(result)
      end

      private

      def sanitize_params(params)
        params[:is_applicant] = params.delete :is_primary_applicant
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